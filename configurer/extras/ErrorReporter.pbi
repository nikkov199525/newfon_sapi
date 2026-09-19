EnableExplicit

Procedure OnErrorCallback ()
Protected CompName.s = Space(#MAX_COMPUTERNAME_LENGTH)
If GetComputerName_(@CompName, #MAX_COMPUTERNAME_LENGTH)
  Protected ErrorMessage$ = Chr(10)+"=========="+Chr(10)+"Unhandled error at "+FormatDate("%yyyy/%mm/%dd %hh:%ii:%ss", Date()) + " on computer "+ CompName + Chr(10) 
Else
ErrorMessage$ = Chr(10)+"=========="+Chr(10)+"Unhandled error at "+FormatDate("%yyyy/%mm/%dd %hh:%ii:%ss", Date()) +  Chr(10) 
EndIf
  ErrorMessage$ + Chr(10)
  ErrorMessage$ + "Error Message:   " + ErrorMessage()      + Chr(10)
  ErrorMessage$ + "Error Code:      " + Str(ErrorCode())    + Chr(10)  
  ErrorMessage$ + "Code Address:    " + Str(ErrorAddress()) + Chr(10)
 
  If ErrorCode() = #PB_OnError_InvalidMemory   
    ErrorMessage$ + "Target Address:  " + Str(ErrorTargetAddress()) + Chr(10)
  EndIf
 
  If ErrorLine() = -1
    ErrorMessage$ + "Sourcecode line: disabled." + Chr(10)
  Else
    ErrorMessage$ + "Sourcecode line: " + Str(ErrorLine()) + Chr(10)
    ErrorMessage$ + "Sourcecode file: " + ErrorFile() + Chr(10)
  EndIf
 
  ErrorMessage$ + Chr(10)
  ErrorMessage$ + "Register content:" + Chr(10)
 
  CompilerSelect #PB_Compiler_Processor 
    CompilerCase #PB_Processor_x86
      ErrorMessage$ + "EAX = " + Str(ErrorRegister(#PB_OnError_EAX)) + Chr(10)
      ErrorMessage$ + "EBX = " + Str(ErrorRegister(#PB_OnError_EBX)) + Chr(10)
      ErrorMessage$ + "ECX = " + Str(ErrorRegister(#PB_OnError_ECX)) + Chr(10)
      ErrorMessage$ + "EDX = " + Str(ErrorRegister(#PB_OnError_EDX)) + Chr(10)
      ErrorMessage$ + "EBP = " + Str(ErrorRegister(#PB_OnError_EBP)) + Chr(10)
      ErrorMessage$ + "ESI = " + Str(ErrorRegister(#PB_OnError_ESI)) + Chr(10)
      ErrorMessage$ + "EDI = " + Str(ErrorRegister(#PB_OnError_EDI)) + Chr(10)
      ErrorMessage$ + "ESP = " + Str(ErrorRegister(#PB_OnError_ESP)) + Chr(10)
 
    CompilerCase #PB_Processor_x64
      ErrorMessage$ + "RAX = " + Str(ErrorRegister(#PB_OnError_RAX)) + Chr(10)
      ErrorMessage$ + "RBX = " + Str(ErrorRegister(#PB_OnError_RBX)) + Chr(10)
      ErrorMessage$ + "RCX = " + Str(ErrorRegister(#PB_OnError_RCX)) + Chr(10)
      ErrorMessage$ + "RDX = " + Str(ErrorRegister(#PB_OnError_RDX)) + Chr(10)
      ErrorMessage$ + "RBP = " + Str(ErrorRegister(#PB_OnError_RBP)) + Chr(10)
      ErrorMessage$ + "RSI = " + Str(ErrorRegister(#PB_OnError_RSI)) + Chr(10)
      ErrorMessage$ + "RDI = " + Str(ErrorRegister(#PB_OnError_RDI)) + Chr(10)
      ErrorMessage$ + "RSP = " + Str(ErrorRegister(#PB_OnError_RSP)) + Chr(10)
      ErrorMessage$ + "Display of registers R8-R15 skipped."         + Chr(10)
 
    CompilerCase #PB_Processor_PowerPC
      ErrorMessage$ + "r0 = " + Str(ErrorRegister(#PB_OnError_r0)) + Chr(10)
      ErrorMessage$ + "r1 = " + Str(ErrorRegister(#PB_OnError_r1)) + Chr(10)
      ErrorMessage$ + "r2 = " + Str(ErrorRegister(#PB_OnError_r2)) + Chr(10)
      ErrorMessage$ + "r3 = " + Str(ErrorRegister(#PB_OnError_r3)) + Chr(10)
      ErrorMessage$ + "r4 = " + Str(ErrorRegister(#PB_OnError_r4)) + Chr(10)
      ErrorMessage$ + "r5 = " + Str(ErrorRegister(#PB_OnError_r5)) + Chr(10)
      ErrorMessage$ + "r6 = " + Str(ErrorRegister(#PB_OnError_r6)) + Chr(10)
      ErrorMessage$ + "r7 = " + Str(ErrorRegister(#PB_OnError_r7)) + Chr(10)
      ErrorMessage$ + "Display of registers r8-R31 skipped."       + Chr(10)
 
  CompilerEndSelect
  
  MessageRequester("Критическая ошибка", ~"Возникла критическая ошибка.\n" + ErrorMessage$, #MB_ICONERROR)
    EndProcedure
