@set @__GenerateTestCases=1 /* [[ Begin batch script
REM ------------------------------------------------------------
REM Copyright (c) Microsoft Corporation.  All rights reserved.
REM Licensed under the MIT License (MIT). See License.txt in the repo root for license information.
REM ------------------------------------------------------------
@echo off
set @__GenerateTestCases=
setlocal

if "%1" == "" goto :Usage
if "%1" == "/?" goto :Usage

cscript.exe //nologo //E:JSCRIPT "%~dpnx0" %~nx0 %1

goto :eof

:Usage
echo %~nx0 [test-config-file]
echo.
echo Processes the test configuration file and generates C# source code containing
echo test case entry points.
goto :eof

REM End batch script ]]
*/
// [[ Begin JScript


var TestType = new Object();
TestType.Taef = "TAEF";
TestType.FederationTest = "FederationTest";
TestType.FabricTest = "FabricTest";
TestType.FederationRandom = "FederationRandom";
TestType.FabricRandom = "FabricRandom";

function GetTimeSpan(durationInMinutes)
{
    var suffix = "FromMinutes(" + durationInMinutes + ")";
    if (durationInMinutes == 0)
    {
        suffix = "Zero";
    }

    return "TimeSpan." + suffix;
}

function GetMethodName(testName, isFunctional)
{
    testName = testName.replace(/\.test\.dll$/i, "_Taef");
    testName = testName.replace(/\.test$/i, "");
    testName = testName.replace(/\./g, "_");
    return (isFunctional ? "Func_" : "Cit_") + testName;
}

function CodeGenerator()
{
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    this.writer = fso.GetStandardStream(1);
    this.methodCount = 0;
}

CodeGenerator.prototype.OutputClassHeader = function(toolName)
{
    this.writer.WriteLine("//------------------------------------------------------------------------------");
    this.writer.WriteLine("// <auto-generated>");
    this.writer.WriteLine("//     This code was generated by a tool.");
    this.writer.WriteLine("//");
    this.writer.WriteLine("//     Changes to this file may cause incorrect behavior and will be lost if");
    this.writer.WriteLine("//     the code is regenerated.");
    this.writer.WriteLine("// </auto-generated>");
    this.writer.WriteLine("//------------------------------------------------------------------------------");
    this.writer.WriteLine();
    this.writer.WriteLine("namespace MS.Test.WinFabric.CITs");
    this.writer.WriteLine("{");
    this.writer.WriteLine("    using System;");
    this.writer.WriteLine("    using System.CodeDom.Compiler;");
    this.writer.WriteLine("    using MS.Test.WinFabric.Harness;");
    this.writer.WriteLine();
    this.writer.WriteLine("    [GeneratedCode(\"" + toolName + "\", \"1.0\")]");
    this.writer.WriteLine("    public partial class NonFijiTestCases");
    this.writer.WriteLine("    {");
}

CodeGenerator.prototype.OutputTestMethod = function(testType, suiteName, testName, durationInMinutes, isFunctional)
{
    ++this.methodCount;
    if (this.methodCount > 1)
    {
        this.writer.WriteLine();
    }

    var methodCall =
        "Run" + testType + "Test(" + 
        "contextInfo, " +
        "\"" + testName + "\", " +
        GetTimeSpan(durationInMinutes) + ")";

    this.writer.WriteLine("        [TestSuite(\"" + suiteName + "\")]");
    this.writer.WriteLine("        public void " + GetMethodName(testName, isFunctional) + "(TestContextInfo contextInfo)");
    this.writer.WriteLine("        {");
    this.writer.WriteLine("            " + methodCall + ";");
    this.writer.WriteLine("        }");
}

CodeGenerator.prototype.OutputClassFooter = function()
{
    this.writer.WriteLine("    }");
    this.writer.WriteLine("}");
}

function Main(toolName, configFile)
{
    var document = new ActiveXObject("Msxml2.DOMDocument.3.0");
    document.async = false;
    document.load(configFile);
    document.setProperty("SelectionLanguage", "XPath");
    var testNodes = document.selectNodes("/configuration/TestsSection/Tests/Test");
    var codeGenerator = new CodeGenerator();

    codeGenerator.OutputClassHeader(toolName);

    var nodeCount = testNodes.length;
    for (var i = 0; i < nodeCount; ++i)
    {
        var testNode = testNodes.item(i);

        var testName = testNode.attributes.getNamedItem("Name").value;
        var testType = testNode.attributes.getNamedItem("Type").value;
        var isFunctional = false;
        var isFunctionalNode = testNode.attributes.getNamedItem("IsFunctional");
        if (isFunctionalNode != null)
        {
            isFunctional = isFunctionalNode.value;
        }

        var suiteName = "Generated_" + testNode.attributes.getNamedItem("Group").value;

        if (testType == TestType.Taef)
        {
            codeGenerator.OutputTestMethod("Taef", suiteName, testName, 0, isFunctional);
        }
        else if (testType == TestType.FederationTest)
        {
            codeGenerator.OutputTestMethod("Federation", suiteName, testName, 0, isFunctional);
        }
        else if (testType == TestType.FabricTest)
        {
            codeGenerator.OutputTestMethod("Fabric", suiteName, testName, 0, isFunctional);
        }
        else if (testType == TestType.FederationRandom)
        {
            codeGenerator.OutputTestMethod("FederationRandom", suiteName, testName, 1080, isFunctional);
        }
        else if (testType == TestType.FabricRandom)
        {
            codeGenerator.OutputTestMethod("FabricRandom", suiteName, testName, 1080, isFunctional);
        }
    }

    codeGenerator.OutputClassFooter();
}

Main(WScript.Arguments(0), WScript.Arguments(1));

// End JScript ]]