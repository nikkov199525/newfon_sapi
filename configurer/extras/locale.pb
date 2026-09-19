; Код для мультиязычности приложения.
; Copyright (C), 2015-2016, O-Team Development.
; Реализация мультиязычности приложения путем работы через Preferences в PureBasic.
; Принимаются файлы кодировки Ascii или одной из кодировок Unicode. При необходимости использовать Unicode, необходим определяющий символ BOM.
; Код кроссплатформенный.
; Мы не хотим комментировать каждый шаг кода. Мы комментируем всего лишь функции и их входные параметры, а также, что они возвращают.

; Структура TRANSLATION_INFO 
; Нужна для получения информации о переводе в приложении, например, при листинге файлов в папке для отображения выбора языка.
Structure TRANSLATION_INFO
LangTitle.s ; Имя языка перевода в оригинальной транскрипции языка.
TranslatedByTitle.s ; Кем сделан перевод.
StringsCount.i ; Общее количество строк для перевода в базе.
TranslatedStringsCount.i ; Количество переведенных строк в базе.
EndStructure

NewMap Strings.s()

; Процедура   GetCurrentLocaleInfo
; Возвращает информацию о текущей локали системы.
; По сути, это обертка над процедурой WINAPI   GetLocaleInfo, только упрощенная и возвращает сразу же строку.
; Параметры:
; Flag.i - флаг, определяющий какую информацию нужно вернуть о текущей локали системы (второй параметр процедуры WINAPI   GetLocaleInfo).
; Возвращает строку.
Procedure.s GetCurrentLocaleInfo(Flag.i)
Protected  Locale.s = Space(50)
If  GetLocaleInfo_(#LOCALE_SYSTEM_DEFAULT, Flag, @Locale, 50)
ProcedureReturn Locale
EndIf
ProcedureReturn #Null$
EndProcedure

; Процедура LoadLocale
; Загружает языковой файл в память по указанному пути.
; Параметры:
; FilePath.s - путь к файлу, содержащему перевод.
; AppTitle.s - Имя приложения. Необходимо для подстановки в сообщениях об ошибке или подстановки через переменную %app% в переводе.
; Возвращает #True в случае, если файл успешно загружен и готов к работе, #False - в случае, если файл по какой-то причине загрузить не удалось.
Procedure.a LoadLocale(FilePath.s, AppTitle.s)
Shared.s AppName, LangTitle, TranslatedByTitle
Shared Strings.s()
AppName = AppTitle
If OpenPreferences(FilePath)
ExaminePreferenceGroups()
While NextPreferenceGroup()
Select PreferenceGroupName()
Case "translation_info"
LangTitle = ReadPreferenceString("lang", "No language title")
TranslatedByTitle = ReadPreferenceString("translated_by", "No language author")
Case "strings"
ExaminePreferenceKeys()
While NextPreferenceKey()
Strings(PreferenceKeyName()) = PreferenceKeyValue()
Wend
EndSelect
Wend
ClosePreferences()
ProcedureReturn #True
Else
ProcedureReturn #False
EndIf
EndProcedure


; Процедура GetCurrentTranslationLanguage
; Возвращает имя языка, который сейчас загружен в память.
Procedure.s GetCurrentTranslationLanguage()
Shared LangTitle.s
ProcedureReturn LangTitle
EndProcedure

; Процедура GetCurrentTranslationTranslator
; Возвращает автора перевода загруженной в память базы.
Procedure.s GetCurrentTranslationTranslator()
Shared TranslatedByTitle.s
ProcedureReturn TranslatedByTitle
EndProcedure

; Процедура GetCurrentTranslationInfo
; Получение информации о загруженной в память базе перевода.
; Параметры:
; *TranslationMeta.TRANSLATION_INFO - указатель на структуру TRANSLATION_INFO, куда нужно записать информацию.
; Возвращает #true, если перевод загружен в память и готов к использованию или #False  в противном случае.
; Примечание: если передать в параметре #Nul, процедура все равно выполнится.
Procedure.a GetCurrentTranslationInfo(*TranslationMeta.TRANSLATION_INFO)
Shared.s AppName, LangTitle, TranslatedByTitle
Shared Strings.s()
Define.a IsInfo, isStrings
If LangTitle And TranslatedByTitle
IsInfo = #True
If *TranslationMeta
With *TranslationMeta
\LangTitle = LangTitle
\TranslatedByTitle = TranslatedByTitle
EndWith
EndIf
EndIf
If MapSize(Strings())
TranslatedItemsCount.i
ForEach Strings()
If Strings() <> ""
TranslatedStringsCount+1
EndIf
Next
If *TranslationMeta
With *TranslationMeta
\StringsCount = MapSize(Strings())
\TranslatedStringsCount = TranslatedStringsCount
EndWith
EndIf
isStrings = #True
EndIf
If IsInfo And isStrings
ProcedureReturn #True
Else
ProcedureReturn #False
EndIf
EndProcedure

; Процедура GetTranslationInfo
; Получение информации о переводе из файла.
; Параметры:
; FilePath.s - путь к файлу с базой.
; *TranslationMeta.TRANSLATION_INFO - указатель на структуру TRANSLATION_INFO, куда нужно записать информацию.
; Возвращает #True, если файл является переводом и прочитать информацию из него удалось, #False - в противном случае.
; Примечание: если передать во втором параметре #Nul, процедура все равно выполнится.
Procedure.a GetTranslationInfo(FilePath.s, *TranslationMeta.TRANSLATION_INFO)
IsTranslation.a
If OpenPreferences(FilePath)
ExaminePreferenceGroups()
While NextPreferenceGroup()
Select PreferenceGroupName()
Case "translation_info"
If *TranslationMeta
*TranslationMeta\LangTitle = ReadPreferenceString("lang", "")
*TranslationMeta\TranslatedByTitle = ReadPreferenceString("translated_by", "")
EndIf
IsTranslation = #True
Case "strings"
Define.i StringsCount, TranslatedStringsCount
ExaminePreferenceKeys()
While NextPreferenceKey()
StringsCount+1
If PreferenceKeyValue()
TranslatedStringsCount+1
EndIf
Wend
If *TranslationMeta
*TranslationMeta\StringsCount = StringsCount
*TranslationMeta\TranslatedStringsCount = TranslatedStringsCount
EndIf
If StringsCount
IsTranslation = #True
EndIf
EndSelect
Wend
ClosePreferences()
EndIf
ProcedureReturn IsTranslation
EndProcedure

Macro ReplaceVar (Variable, FinishString)
If FindString(Message, Variable)
Message = ReplaceString(Message, Variable, FinishString, #PB_String_CaseSensitive)
EndIf
EndMacro

; Получение перевода по оригиналу в базе.
Procedure.s trl(OrigString.s)
Shared Strings.s()
Shared AppName.s
Protected Message.s = Strings(OrigString)
If Message = ""
Message = OrigString
EndIf
ReplaceVar("%chr_nl%", Chr(10))
ReplaceVar("%chr_tab%", Chr(9))
ReplaceVar("%chr_quote%", Chr(34))
ReplaceVar("%app%", AppName)
ProcedureReturn Message
            EndProcedure


; Получение перевода по оригиналу в базе с использованием переменных
; Второй параметр - мап с переменной.
; в ключе мапа должен быть паттерн для замены переменной.
; В значении мапа по данному ключу должно быть значение переменной.
Procedure.s trlex(OrigString.s, Map Variables.s())
Protected Message.s = trl(OrigString)
ForEach Variables()
If FindString(Message, MapKey(Variables()))
Message = ReplaceString(Message, MapKey(Variables()), Variables())
EndIf
Next
ProcedureReturn Message
EndProcedure


; Склонение необходимой части строки, по числовому значению.
; Пример: 1 друг, 13 друзей, 182 книги.
; Чтобы подставить переданное число, используйте переменную %d.
; формат строки:
; У вас %d дру[зей|г|га].
; первая часть блока - окончание в случае с нулевым и числами более пяти или чисел в первом десятке.
; Вторая часть блока - окончание в случае чисел, заканчивающихся на единицу.
; Третья часть блока - окончание в случае чисел, заканчивающихся на от двух до четырех.
; К примеру, если вызов процедуры будет выглядеть так:
; Debug CaseStringByNum("На столе %d книг[|а\и].", 91)
; Результат будет "На столе 91 книга.
Procedure.s CaseStringByNum(Text.s, Num.i)
If FindString(Text, "[") And FindString(Text, "]")
While FindString(Text, "[") Or  FindString(Text, "]")
Leftbr.i = FindString(Text, "[")
Rightbr.i = FindString(Text, "]")
Pattern$ = Mid(Text, Leftbr+1, Rightbr-Leftbr-1)
ReservedString$ = Mid(Text, Rightbr+1)
Text = Left(Text, Leftbr-1)
If Val(Right(Str(Num), 2)) >= 11 And Val(Right(Str(Num), 2)) <= 14
Text + StringField(Pattern$, 1, "|")
Else
Select Val(Right(Str(Num), 1))
Case 1
Text + StringField(Pattern$, 2, "|")
Case 2 To 4
Text + StringField(Pattern$, 3, "|")
Default
Text + StringField(Pattern$, 1, "|")
EndSelect
EndIf
Text + Right(ReservedString$, Len(ReservedString$))
Wend
EndIf
If FindString(Text, "%d")
Text = ReplaceString(Text, "%d", Str(Num))
EndIf
ProcedureReturn Text
EndProcedure

; Процедура UnloadLocale
; Выгружает базу и очищает все участки памяти.
Procedure UnloadLocale()
Shared.s AppName, LangTitle, TranslatedByTitle
Shared Strings.s()
AppName = #Null$
LangTitle = #Null$
TranslatedByTitle = #Null$
ClearMap(Strings())
; используется ClearMap вместо FreeMap, поскольку возможна перезагрузка перевода в память. Таким образом, мы не имеем права полностью релизить мап строк.
EndProcedure
