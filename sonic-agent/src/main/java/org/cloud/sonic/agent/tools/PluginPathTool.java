/*
 *   sonic-agent  Agent of Sonic Cloud Real Machine Platform.
 *   Copyright (C) 2022 SonicCloudOrg
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
package org.cloud.sonic.agent.tools;

import java.io.File;

/**
 * 插件目录统一路径：{user.dir}/plugins（与 ResourceConfig /download/** 一致）
 */
public final class PluginPathTool {

    /** 插件根目录，默认与工作目录同级的 plugins 目录 */
    public static final File PLUGINS_DIR = new File(System.getProperty("user.dir", "."), "plugins");

    private PluginPathTool() {
    }

    /** 插件目录下相对路径对应的 File */
    public static File file(String relativePath) {
        return new File(PLUGINS_DIR, relativePath.replace("/", File.separator));
    }

    /** 插件目录下相对路径的绝对路径字符串 */
    public static String path(String relativePath) {
        return file(relativePath).getAbsolutePath();
    }
}
