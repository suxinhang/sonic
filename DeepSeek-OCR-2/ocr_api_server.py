#!/usr/bin/env python3
"""
DeepSeek-OCR-2 API Server for Sonic Platform
提供HTTP API接口供Java后端调用
"""
import os
import sys
import json
import base64
import tempfile
from flask import Flask, request, jsonify
from flask_cors import CORS
from transformers import AutoModel, AutoTokenizer
import torch
from PIL import Image
import io

app = Flask(__name__)
CORS(app)

# 全局变量存储模型
model = None
tokenizer = None
model_loaded = False

def load_model():
    """加载DeepSeek-OCR-2模型"""
    global model, tokenizer, model_loaded
    
    if model_loaded:
        return True
    
    try:
        os.environ["CUDA_VISIBLE_DEVICES"] = os.getenv("CUDA_VISIBLE_DEVICES", "0")
        model_name = 'deepseek-ai/DeepSeek-OCR-2'
        
        print(f"Loading model: {model_name}")
        tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
        model = AutoModel.from_pretrained(
            model_name, 
            _attn_implementation='flash_attention_2', 
            trust_remote_code=True, 
            use_safetensors=True
        )
        model = model.eval().cuda().to(torch.bfloat16)
        model_loaded = True
        print("Model loaded successfully")
        return True
    except Exception as e:
        print(f"Error loading model: {e}")
        return False

@app.route('/health', methods=['GET'])
def health():
    """健康检查"""
    return jsonify({
        "status": "ok",
        "model_loaded": model_loaded
    })

@app.route('/ocr/recognize', methods=['POST'])
def recognize():
    """OCR识别接口"""
    try:
        if not model_loaded:
            if not load_model():
                return jsonify({
                    "success": False,
                    "error": "Failed to load model"
                }), 500
        
        # 获取参数
        mode = request.form.get('mode', 'document')
        save_results = request.form.get('saveResults', 'false').lower() == 'true'
        
        # 获取图片
        if 'file' in request.files:
            file = request.files['file']
            image = Image.open(io.BytesIO(file.read()))
        elif 'imageUrl' in request.form:
            import urllib.request
            image_url = request.form['imageUrl']
            with urllib.request.urlopen(image_url) as response:
                image = Image.open(io.BytesIO(response.read()))
        elif 'base64Image' in request.form:
            base64_data = request.form['base64Image']
            if ',' in base64_data:
                base64_data = base64_data.split(',')[1]
            image_data = base64.b64decode(base64_data)
            image = Image.open(io.BytesIO(image_data))
        else:
            return jsonify({
                "success": False,
                "error": "No image provided"
            }), 400
        
        # 保存临时图片
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp_file:
            image.save(tmp_file.name)
            image_path = tmp_file.name
        
        try:
            # 构建prompt
            prompt = "<image>\n<|grounding|>Convert the document to markdown. " if mode == "document" else "<image>\nFree OCR. "
            
            # 创建输出目录
            output_dir = os.getenv("OCR_OUTPUT_PATH", "/tmp/ocr_output")
            os.makedirs(output_dir, exist_ok=True)
            
            # 执行OCR
            result = model.infer(
                tokenizer,
                prompt=prompt,
                image_file=image_path,
                output_path=output_dir,
                base_size=1024,
                image_size=768,
                crop_mode=True,
                save_results=save_results
            )
            
            return jsonify({
                "success": True,
                "mode": mode,
                "text": str(result) if result else "",
                "outputPath": output_dir if save_results else None
            })
        finally:
            # 清理临时文件
            try:
                os.unlink(image_path)
            except:
                pass
                
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.getenv("OCR_SERVER_PORT", "8888"))
    host = os.getenv("OCR_SERVER_HOST", "127.0.0.1")
    
    print(f"Starting OCR API Server on {host}:{port}")
    app.run(host=host, port=port, debug=False)

