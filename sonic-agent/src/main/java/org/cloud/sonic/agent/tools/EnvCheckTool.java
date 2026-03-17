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

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

/**
 * 检查环境
 *
 * @author JayWenStar, Eason
 * @date 2021/12/5 15:00
 */
@Component
public class EnvCheckTool {

    public static String system;
    private final String HELP_URL = "https://sonic-cloud.cn/deploy/agent-deploy.html#%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98-q-a";

    public static String adbVersion = "unknown";
    public static String sasPrintVersion = "unknown";
    public static String sibPrintVersion = "unknown";
    public static String sgmPrintVersion = "unknown";

    static {
        system = System.getProperty("os.name").toLowerCase();
    }

    @Value("${sonic.sas}")
    private String sasVersion;

    @Value("${sonic.sib}")
    private String sibVersion;

    @Value("${sonic.sgm}")
    private String sgmVersion;

    @Bean
    public boolean checkEnv(ConfigurableApplicationContext context) {
        System.out.println("===================== Checking the Environment =====================");
        try {
            checkConfigFiles();
            checkMiniFiles();
            checkPlugins();
        } catch (Exception e) {
            System.out.println(printInfo(e.getMessage()));
            System.out.println("=========================== Check results ===========================");
            printAllFail("Unfortunately, some of the check items did not pass!");
            System.out.println(this);
            System.out.println("========================== Check Completed ==========================");
            context.close();
            System.exit(0);
        }
        System.out.println("=========================== Check results ===========================");
        printAllPass("Congratulations, all check items have been done!");
        System.out.println(this);
        System.out.println("========================== Check Completed ==========================");
        return true;
    }

    /**
     * 检查本地文件
     */
    public void checkConfigFiles() {
        String type = "Check config folders";
        printChecking(type);
        File config = new File("config/application-sonic-agent.yml");
        if (system.contains("linux") || system.contains("mac")) {
            try {
                Runtime.getRuntime().exec(new String[]{"sh", "-c", String.format("chmod -R 777 %s", new File("").getAbsolutePath())});
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        if (config.exists()) {
            printPass(type);
        } else {
            printFail(type);
            throw new RuntimeException("Missing file! Please ensure that `config` (containing application-sonic-agent.yml) folders in the current directory");
        }
    }

    public void checkMiniFiles() {
        String type = "Check mini folders";
        printChecking(type);
        File mini = new File("mini");
        if (mini.exists()) {
            printPass(type);
        } else {
            printFail(type);
            throw new RuntimeException("Missing file! Please ensure that `mini` folders in the current directory");
        }
    }

    private boolean checkADB() {
        String type = "Check ADB environment";
        printChecking(type);
        String path = System.getenv("ANDROID_HOME");
        if (path != null) {
            path += File.separator + "platform-tools" + File.separator + "adb";
        } else {
            path = PluginPathTool.path("adb");
        }
        if (system.contains("win")) {
            path += ".exe";
        }
        File adb = new File(path);
        if (adb.exists()) {
            adb.setExecutable(true);
            adb.setWritable(true);
            adb.setReadable(true);
            List<String> ver = ProcessCommandTool.getProcessLocalCommand(String.format("\"%s\" version", adb.getAbsolutePath()));
            if (ver.size() == 0) {
                printFail(type);
                throw new RuntimeException("Can not use adb! Please ensure that `adb` command useful!" + (system.toUpperCase(Locale.ROOT).contains("MAC") ? " You can see " + HELP_URL + " ." : ""));
            } else {
                adbVersion = ver.get(0);
                printPass(type);
                return true;
            }
        } else {
            printFail(type);
            throw new RuntimeException("Missing file! Please ensure that `adb` command useful or `plugins` folder (containing adb) at " + PluginPathTool.PLUGINS_DIR.getAbsolutePath());
        }
    }

    private boolean checkSAS() {
        String type = "Check sonic-android-supply plugin";
        printChecking(type);
        File sasBinary = PluginPathTool.file("sonic-android-supply" + (system.contains("win") ? ".exe" : ""));
        if (sasBinary.exists()) {
            sasBinary.setExecutable(true);
            sasBinary.setWritable(true);
            sasBinary.setReadable(true);
            List<String> ver = ProcessCommandTool.getProcessLocalCommand(String.format("\"%s\" version", sasBinary.getAbsolutePath()));
            sasPrintVersion = (ver.size() == 0 ? "null" : ver.get(0));
            if (ver.size() == 0 || !BytesTool.versionCheck(sasVersion, ver.get(0))) {
                printWarn(type + " (missing or invalid, Android supply disabled)");
                return true;
            } else {
                printPass(type);
                return true;
            }
        } else {
            printWarn(type + " (not found, Android supply disabled)");
            return true;
        }
    }

    private boolean checkSIB() {
        String type = "Check sonic-ios-bridge plugin";
        printChecking(type);
        File sibBinary = PluginPathTool.file("sonic-ios-bridge" + (system.contains("win") ? ".exe" : ""));
        if (sibBinary.exists()) {
            sibBinary.setExecutable(true);
            sibBinary.setWritable(true);
            sibBinary.setReadable(true);
            List<String> ver = ProcessCommandTool.getProcessLocalCommand(String.format("\"%s\" version", sibBinary.getAbsolutePath()));
            sibPrintVersion = (ver.size() == 0 ? "null" : ver.get(0));
            if (ver.size() == 0 || !BytesTool.versionCheck(sibVersion, ver.get(0))) {
                printWarn(type + " (missing or invalid, iOS bridge disabled)");
                return true;
            } else {
                printPass(type);
                return true;
            }
        } else {
            printWarn(type + " (not found, iOS bridge disabled)");
            return true;
        }
    }

    private boolean checkSGM() {
        String type = "Check sonic-go-mitmproxy plugin";
        printChecking(type);
        File sgmBinary = PluginPathTool.file("sonic-go-mitmproxy" + (system.contains("win") ? ".exe" : ""));
        if (sgmBinary.exists()) {
            sgmBinary.setExecutable(true);
            sgmBinary.setWritable(true);
            sgmBinary.setReadable(true);
            List<String> ver = ProcessCommandTool.getProcessLocalCommand(String.format("\"%s\" -version", sgmBinary.getAbsolutePath()));
            sgmPrintVersion = (ver.size() == 0 ? "null" : ver.get(0));
            if (ver.size() == 0 || !BytesTool.versionCheck(sgmVersion, ver.get(0).replace("sonic-go-mitmproxy:", "").trim())) {
                printWarn(type + " (missing or invalid, mitmproxy disabled)");
                return true;
            } else {
                printPass(type);
                return true;
            }
        } else {
            printWarn(type + " (not found, mitmproxy disabled)");
            return true;
        }
    }

    private boolean checkAPKs() {
        String type = "Check apk files";
        printChecking(type);
        File saa = PluginPathTool.file("sonic-android-apk.apk");
        File saus = PluginPathTool.file("sonic-appium-uiautomator2-server.apk");
        File saust = PluginPathTool.file("sonic-appium-uiautomator2-server-test.apk");
        if (saa.exists() && saus.exists() && saust.exists()) {
            printPass(type);
            return true;
        } else {
            printWarn(type + " (incomplete, Android automation may be limited)");
            return true;
        }
    }

    public void checkPlugins() {
        String type = "Check all plugins";
        File plugins = PluginPathTool.PLUGINS_DIR;
        if (plugins.exists()) {
            if (checkADB() && checkSAS() && checkSIB() && checkSGM() && checkAPKs()) {
                printPass(type);
            }
        } else {
            printFail(type);
            throw new RuntimeException("Missing file! Please ensure that `plugins` folder exists at " + PluginPathTool.PLUGINS_DIR.getAbsolutePath());
        }
    }

    public void printAllPass(String s) {
        if (system.contains("win")) {
            System.out.println("✔ " + s + " ✔");
        } else {
            System.out.println("\33[32;1m✨ " + s + " ✨\033[0m");
        }
    }

    public void printAllFail(String s) {
        if (system.contains("win")) {
            System.out.println("× " + s);
        } else {
            System.out.println("\33[31;1m❌ " + s + " \033[0m");
        }
    }

    public void printPass(String s) {
        if (system.contains("win")) {
            System.out.println("→ " + s + " Pass √");
        } else {
            System.out.println("\33[32;1m👉 " + s + " Pass ✔\033[0m");
        }
    }

    public void printFail(String s) {
        if (system.contains("win")) {
            System.out.println("→ " + s + " Fail ×");
        } else {
            System.out.println("\33[31;1m👉 " + s + " Fail ❌\033[0m");
        }
    }

    public void printWarn(String s) {
        if (system.contains("win")) {
            System.out.println("→ " + s + " Skip (optional)");
        } else {
            System.out.println("\33[33;1m👉 " + s + " Skip (optional) ⚠\033[0m");
        }
    }

    public String printInfo(String s) {
        if (system.contains("win")) {
            return "· " + s;
        } else {
            return "\33[34;1m" + s + "\033[0m";
        }
    }

    public void printChecking(String s) {
        s = s.replace("Check", "Checking");
        if (system.contains("win")) {
            System.out.println("· " + s + " ...");
        } else {
            System.out.println("\33[34;1m" + s + "...\033[0m");
        }
    }

    public static String exeCmd(boolean getError, String commandStr) throws IOException, InterruptedException {

        if (system.contains("win")) {
            return exeCmd(getError, "cmd", "/c", commandStr);
        }
        if (system.contains("linux") || system.contains("mac")) {
            return exeCmd(getError, "sh", "-c", commandStr);
        }
        throw new RuntimeException("error system: " + system);
    }

    public static String exeCmd(boolean getError, String... commandStr) throws IOException, InterruptedException {

        String result = "";
        Process ps = Runtime.getRuntime().exec(commandStr);
        ps.waitFor();
        BufferedReader br = new BufferedReader(new InputStreamReader(ps.getInputStream(), Charset.forName("GBK")));
        ;
        if (getError && ps.getErrorStream().available() > 0) {
            br = new BufferedReader(new InputStreamReader(ps.getErrorStream(), Charset.forName("GBK")));
        }
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = br.readLine()) != null) {
            sb.append(line).append("\n");
        }
        result = sb.toString();

        if (!StringUtils.hasText(result)) {
            Object[] c = Arrays.stream(commandStr).toArray();
            throw new RuntimeException(String.format("execute【%s】error!", c.length > 0 ? c[c.length - 1] : "unknown"));
        }
        return result;
    }

    @Override
    public String toString() {
        return printInfo("System: ") + system + "\n" +
                printInfo("ADB version: ") + adbVersion + "\n" +
                printInfo("sonic-android-supply version: ") + sasPrintVersion + "\n" +
                printInfo("sonic-ios-bridge version: ") + sibPrintVersion + "\n" +
                printInfo("sonic-go-mitmproxy version: ") + sgmPrintVersion;
    }
}