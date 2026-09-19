#Semaphore_Postfix = "_Instance"



Procedure.i RunInstance(AppTitle.s)
    AppTitle = ReplaceString(AppTitle, " ", "_")
Protected MySemaphoreHandle.i = CreateSemaphore_(#NUL, 0, 1, AppTitle+#Semaphore_Postfix)
If MySemaphoreHandle <> 0 And GetLastError_() = #ERROR_ALREADY_EXISTS
ProcedureReturn #NUL
Else
ProcedureReturn MySemaphoreHandle
EndIf
EndProcedure

Procedure ExistInstance(AppTitle.s)
AppTitle = ReplaceString(AppTitle, " ", "_")
Protected MySemaphoreHandle.i = OpenSemaphore_(#SEMAPHORE_ALL_ACCESS,  0, AppTitle+#Semaphore_Postfix)
If MySemaphoreHandle
  CloseHandle_(MySemaphoreHandle)
  ProcedureReturn #True
EndIf
EndProcedure

Procedure.a CloseInstance(handle.i)
If handle
CloseHandle_(handle)
ProcedureReturn #True
Else
ProcedureReturn #False
EndIf
EndProcedure
