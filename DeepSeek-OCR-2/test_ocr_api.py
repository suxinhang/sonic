#!/usr/bin/env python3
"""
DeepSeek-OCR-2 API 测试脚本
测试 ocr_api_server 的 /health 和 /ocr/recognize 接口
仅使用 Python 标准库，无需 pip 安装依赖。
"""
import os
import sys
import argparse
import base64
import json
import urllib.request
import urllib.error
import urllib.parse

# 默认配置（与 start_ocr_service.sh 一致）
DEFAULT_HOST = os.getenv("OCR_SERVER_HOST", "127.0.0.1")
DEFAULT_PORT = int(os.getenv("OCR_SERVER_PORT", "8888"))


def get_base_url(host: str, port: int) -> str:
    return f"http://{host}:{port}"


def _http_get(url: str, timeout: int = 10):
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.status, r.read().decode("utf-8")


def test_health(base_url: str) -> bool:
    """测试健康检查接口 GET /health"""
    print(">>> 测试 GET /health")
    try:
        status, body = _http_get(f"{base_url}/health")
        if status != 200:
            print(f"    ✗ 失败: HTTP {status}")
            return False
        data = json.loads(body)
        print(f"    状态: {data.get('status', '?')}")
        print(f"    模型已加载: {data.get('model_loaded', '?')}")
        if not data.get("model_loaded"):
            print("    提示: 模型未加载，首次 OCR 请求会尝试加载（需 GPU/CUDA 与足够显存）")
        print("    ✓ 通过")
        return True
    except urllib.error.URLError as e:
        print(f"    ✗ 失败: {e}")
        return False
    except Exception as e:
        print(f"    ✗ 失败: {e}")
        return False


def _multipart_form_data(fields: dict, files: dict) -> tuple:
    """构造 multipart/form-data 体和 boundary。fields 与 files 均为 name -> (filename, bytes) 或 name -> value(str)."""
    boundary = "----WebKitFormBoundary" + base64.b64encode(os.urandom(16)).decode("ascii").rstrip("=")
    parts = []
    for name, value in fields.items():
        parts.append(
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{value}\r\n".encode("utf-8")
        )
    for name, value in files.items():
        if isinstance(value, tuple):
            filename, content = value
        else:
            filename, content = name, value
        if isinstance(content, str):
            content = content.encode("utf-8")
        parts.append(
            f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"; filename=\"{filename}\"\r\nContent-Type: application/octet-stream\r\n\r\n".encode("utf-8")
        )
        parts.append(content)
        parts.append(b"\r\n")
    parts.append(f"--{boundary}--\r\n".encode("utf-8"))
    body = b"".join(parts)
    return body, boundary


def test_recognize_file(base_url: str, image_path: str, mode: str = "document") -> bool:
    """测试 OCR 识别接口 - 使用文件上传 POST /ocr/recognize"""
    print(f">>> 测试 POST /ocr/recognize (file, mode={mode})")
    if not os.path.isfile(image_path):
        print(f"    ✗ 文件不存在: {image_path}")
        return False
    try:
        with open(image_path, "rb") as f:
            image_bytes = f.read()
        filename = os.path.basename(image_path)
        body, boundary = _multipart_form_data(
            {"mode": mode, "saveResults": "false"},
            {"file": (filename, image_bytes)},
        )
        req = urllib.request.Request(
            f"{base_url}/ocr/recognize",
            data=body,
            method="POST",
            headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        )
        with urllib.request.urlopen(req, timeout=120) as r:
            resp_body = r.read().decode("utf-8")
        resp = json.loads(resp_body)
        if not resp.get("success"):
            print(f"    ✗ 接口返回 success=False: {resp.get('error', resp)}")
            return False
        text = (resp.get("text") or "")[:200]
        if len((resp.get("text") or "")) > 200:
            text += "..."
        print(f"    识别文本预览: {text!r}")
        print("    ✓ 通过")
        return True
    except urllib.error.HTTPError as e:
        print(f"    ✗ 失败: HTTP {e.code} {e.reason}")
        err_body = ""
        try:
            err_body = e.read().decode("utf-8")
            err_data = json.loads(err_body)
            print(f"    响应: {err_data}")
            if err_data.get("detail"):
                print(f"    原因: {err_data['detail']}")
        except Exception:
            if err_body:
                print(f"    响应体: {err_body[:500]}")
        return False
    except Exception as e:
        print(f"    ✗ 失败: {e}")
        return False


def test_recognize_base64(base_url: str, image_path: str) -> bool:
    """测试 OCR 识别接口 - 使用 base64 图片 POST /ocr/recognize"""
    print(">>> 测试 POST /ocr/recognize (base64Image)")
    if not os.path.isfile(image_path):
        print(f"    ✗ 文件不存在: {image_path}")
        return False
    try:
        with open(image_path, "rb") as f:
            b64 = base64.b64encode(f.read()).decode("utf-8")
        data = urllib.parse.urlencode({
            "base64Image": b64,
            "mode": "free",
            "saveResults": "false",
        }).encode("utf-8")
        req = urllib.request.Request(
            f"{base_url}/ocr/recognize",
            data=data,
            method="POST",
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        with urllib.request.urlopen(req, timeout=120) as r:
            resp_body = r.read().decode("utf-8")
        resp = json.loads(resp_body)
        if not resp.get("success"):
            print(f"    ✗ 接口返回 success=False: {resp.get('error', resp)}")
            return False
        print(f"    识别文本长度: {len(resp.get('text') or '')} 字符")
        print("    ✓ 通过")
        return True
    except urllib.error.HTTPError as e:
        print(f"    ✗ 失败: HTTP {e.code}")
        try:
            err_body = e.read().decode("utf-8")
            err_data = json.loads(err_body)
            if err_data.get("detail"):
                print(f"    原因: {err_data['detail']}")
        except Exception:
            pass
        return False
    except Exception as e:
        print(f"    ✗ 失败: {e}")
        return False


def create_sample_image(path: str) -> bool:
    """创建一张简单的测试用图片（含简单文字/图形）"""
    try:
        from PIL import Image, ImageDraw, ImageFont

        img = Image.new("RGB", (400, 100), color=(255, 255, 255))
        draw = ImageDraw.Draw(img)
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 24)
        except OSError:
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 24)
            except OSError:
                font = ImageFont.load_default()
        draw.text((20, 35), "Hello OCR Test 123", fill=(0, 0, 0), font=font)
        img.save(path)
        return True
    except ImportError:
        print("创建示例图片需要 Pillow: pip install Pillow")
        return False
    except Exception as e:
        print(f"创建示例图片失败: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="DeepSeek-OCR-2 API 测试脚本")
    parser.add_argument(
        "--host",
        default=DEFAULT_HOST,
        help=f"OCR 服务地址 (默认: {DEFAULT_HOST})",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=DEFAULT_PORT,
        help=f"OCR 服务端口 (默认: {DEFAULT_PORT})",
    )
    parser.add_argument(
        "--image",
        "-i",
        metavar="PATH",
        help="测试用的图片路径；不传则只测 /health，可用 --sample 生成临时图",
    )
    parser.add_argument(
        "--sample",
        action="store_true",
        help="若无 --image，则生成一张示例图片并测试 /ocr/recognize",
    )
    parser.add_argument(
        "--no-base64",
        action="store_true",
        help="不测试 base64 方式上传，仅测 file 上传",
    )
    parser.add_argument(
        "--mode",
        choices=("document", "free"),
        default="document",
        help="OCR 模式 (默认: document)",
    )
    args = parser.parse_args()

    base_url = get_base_url(args.host, args.port)
    print(f"OCR API 地址: {base_url}\n")

    passed = 0
    failed = 0

    # 1. 健康检查
    if test_health(base_url):
        passed += 1
    else:
        failed += 1
        script_dir = os.path.dirname(os.path.abspath(__file__))
        start_script = os.path.join(script_dir, "start_ocr_service.sh")
        if os.path.isfile(start_script):
            print(f"\n健康检查未通过，请先启动 OCR 服务:")
            print(f"  cd {script_dir} && ./start_ocr_service.sh")
        else:
            print("\n健康检查未通过，请先启动 OCR 服务")
        sys.exit(1)

    # 2. 识别接口（需要图片）
    image_path = args.image
    if args.sample and not image_path:
        sample_path = os.path.join(os.path.dirname(__file__), ".test_sample_image.png")
        if create_sample_image(sample_path):
            image_path = sample_path
            print(f"\n已生成示例图片: {image_path}\n")

    if image_path:
        if test_recognize_file(base_url, image_path, mode=args.mode):
            passed += 1
        else:
            failed += 1
        if not args.no_base64:
            if test_recognize_base64(base_url, image_path):
                passed += 1
            else:
                failed += 1
        if args.sample and image_path.endswith(".test_sample_image.png"):
            try:
                os.remove(image_path)
            except OSError:
                pass
    else:
        print("\n未提供图片，跳过 /ocr/recognize 测试（可使用 --image PATH 或 --sample）")

    print("\n" + "=" * 50)
    print(f"结果: 通过 {passed}, 失败 {failed}")
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
