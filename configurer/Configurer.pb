XIncludeFile "extras\locale.pb"
XIncludeFile "extras\OneInstance.pb"
XIncludeFile "extras\string.pb"

; The archived UI uses implicit variables; included helpers enable explicit mode.
DisableExplicit

#AppTitle = "NewfonConfigurer"

Enumeration Windows
#MainWindow
#AddSimpleDictWindow
EndEnumeration

Enumeration MainGadgets (1000)
#UsePause_Check
#Pause_Track
#Intonation_Track
#UseDictionary_Combo
#SilenceAtBegin_track
#SilenceAtEnd_track
#EnglishLetters_ListIcon
#EnglishLetters_AddBtn
#RussianLetters_ListIcon
#EnglishPronunciation_ListIcon
#SpecSymbols_ListIcon
#UserDict_ListIcon
#Docs_Btn
#Apply_Btn
#AddEntry_Btn
#EditEntry_Btn
#DeleteEntry_Btn
EndEnumeration

Enumeration AddSimpleDictGadgets (2000)
#AddSource_String
#AddReplace_String
#Add_ModeCombo
#OK_Btn
#Cancel_Btn
#Add_ErrorTip
EndEnumeration

#MNU_Context1 = 0

Enumeration MenuItems (1)
#MI_Add
#MI_Edit
#MI_Delete
; Псевдо-элементы для реализации горячих клавиш
#PMI_ApplyConfigs
#PMI_AddDictEntry
#PMI_Docs
EndEnumeration

Enumeration WhereFlags
#WF_EnglishLetters
#WF_RussianLetters
#WF_EnglishPronunciation
#WF_SpecSymbols
#WF_UserDict
EndEnumeration

EnumerationBinary CheckForbiddenStringsFlags
#ChFS_AlphaLatin
#ChFS_AlphaCyrillic
#ChFS_Digits
EndEnumeration

; Сообщения ньюфону, которые будем передавать для всяких разных сервисных моментов. Пока не используется. Точнее, используется, но впустую.

#NFMSG_ReloadConfigs = 1


Structure SIMPLEDICT
Source.s
Replace.s
EndStructure

Structure SYMBOLDICT Extends SIMPLEDICT
SymbolMode.a
EndStructure

Declare InformNewfon(MSG.i)

; Переменные параметров
Global Pref_Pause.i,
Pref_Intonation.i,
Pref_SilenceAtBegin.i,
Pref_SilenceAtEnd.i,
Pref_UseDictionary.b,
NewList Pref_EnglishLetters.SIMPLEDICT(),
NewList Pref_RussianLetters.SIMPLEDICT(),
NewList Pref_EnglishPronunciation.SIMPLEDICT(),
NewList Pref_SpecSymbols.SYMBOLDICT(),
NewList Pref_UserDict.SIMPLEDICT()

Global.a ConfigsChanged
Global .i AppInstance = RunInstance(#AppTitle)

XIncludeFile "extras\PrefsExtras.pb"

; [english_pronunciation] holds Latin combinations only, as in the original format.
; Other characters there come from older builds and belong in [symbols].
Procedure MigrateCharacterReplacements()
Protected i.i, c.s, Latin.i, Found.i
ForEach Pref_EnglishPronunciation()
Latin = Bool(Pref_EnglishPronunciation()\Source <> "")
For i = 1 To Len(Pref_EnglishPronunciation()\Source)
c = Mid(Pref_EnglishPronunciation()\Source, i, 1)
If c < "a" Or c > "z" : Latin = #False : Break : EndIf
Next
If Not Latin
Found = #False
ForEach Pref_SpecSymbols()
If Pref_SpecSymbols()\Source = Pref_EnglishPronunciation()\Source : Found = #True : Break : EndIf
Next
If Not Found
LastElement(Pref_SpecSymbols())
AddElement(Pref_SpecSymbols())
Pref_SpecSymbols()\Source = Pref_EnglishPronunciation()\Source
Pref_SpecSymbols()\Replace = Pref_EnglishPronunciation()\Replace
Pref_SpecSymbols()\SymbolMode = 1
EndIf
DeleteElement(Pref_EnglishPronunciation())
EndIf
Next
EndProcedure

Procedure.b LoadConfig()
Protected Path$ =  NewfonConfigDir()+"prefs.ini"
Protected ConfigBeenOpened.a = OpenPreferences(Path$, #PB_Preference_GroupSeparator, #PB_UTF8)
If Not ConfigBeenOpened
MessageRequester(trl("Первое использование Newfon SAPI"), trl(~"Команда O-Team Development рада, что вы выбрали синтезатор Newfon!\nВ память о Сергее Шишминцеве, мы продолжаем начатое им дело и придаем синтезатору Newfon новую жизнь. Теперь Newfon представлен как SAPI5-совместимый синтезатор!\nВы только что установили Newfon SAPI. Теперь необходимо его сконфигурировать. Сейчас будут применены настройки по умолчанию. Вы можете изменить их на свой вкус в следующем окне."), #PB_MessageRequester_Info)
EndIf
PreferenceGroup("General")
LoadExtraParameters()
Pref_Pause = ReadPreferenceInteger("pause", -1)
Pref_UseDictionary = ReadPreferenceLong("use_dictionary", 2)
Pref_Intonation = ReadPreferenceInteger("intonation", 50)
Pref_SilenceAtBegin = ReadPreferenceInteger("silence_at_begin", 0)
Pref_SilenceAtEnd = ReadPreferenceInteger("silence_at_end", 0)
If ConfigBeenOpened
PreferenceGroup("english_letters")
While NextPreferenceKey()
AddElement(Pref_EnglishLetters())
With Pref_EnglishLetters()
\Source = PreferenceKeyName()
\Replace = PreferenceKeyValue()
EndWith
Wend
PreferenceGroup("russian_letters")
While NextPreferenceKey()
AddElement(Pref_RussianLetters())
With Pref_RussianLetters()
\Source = PreferenceKeyName()
\Replace = PreferenceKeyValue()
EndWith
Wend
PreferenceGroup("english_pronunciation")
While NextPreferenceKey()
AddElement(Pref_EnglishPronunciation())
With Pref_EnglishPronunciation()
\Source = PreferenceKeyName()
\Replace = PreferenceKeyValue()
EndWith
Wend
PreferenceGroup("symbols")
While NextPreferenceKey()
AddElement(Pref_SpecSymbols())
With Pref_SpecSymbols()
\Source = PreferenceKeyName()
\Replace = StringField(PreferenceKeyValue(), 1, ":")
\SymbolMode = Val(StringField(PreferenceKeyValue(), 2, ":"))
EndWith
Wend
MigrateCharacterReplacements()
Else
With Pref_EnglishLetters()
AddElement(Pref_EnglishLetters()): \Source = "a": \Replace = "эй"
AddElement(Pref_EnglishLetters()): \Source = "b": \Replace = "би"
AddElement(Pref_EnglishLetters()): \Source = "c": \Replace = "си"
AddElement(Pref_EnglishLetters()): \Source = "d": \Replace = "ди"
AddElement(Pref_EnglishLetters()): \Source = "e": \Replace = "и"
AddElement(Pref_EnglishLetters()): \Source = "f": \Replace = "эф"
AddElement(Pref_EnglishLetters()): \Source = "g": \Replace = "джи"
AddElement(Pref_EnglishLetters()): \Source = "h": \Replace = "эйч"
AddElement(Pref_EnglishLetters()): \Source = "i": \Replace = "ай"
AddElement(Pref_EnglishLetters()): \Source = "j": \Replace = "джэй"
AddElement(Pref_EnglishLetters()): \Source = "k": \Replace = "кей"
AddElement(Pref_EnglishLetters()): \Source = "l": \Replace = "эл"
AddElement(Pref_EnglishLetters()): \Source = "m": \Replace = "эм"
AddElement(Pref_EnglishLetters()): \Source = "n": \Replace = "эн"
AddElement(Pref_EnglishLetters()): \Source = "o": \Replace = "оу"
AddElement(Pref_EnglishLetters()): \Source = "p": \Replace = "пи"
AddElement(Pref_EnglishLetters()): \Source = "q": \Replace = "къю"
AddElement(Pref_EnglishLetters()): \Source = "r": \Replace = "ар"
AddElement(Pref_EnglishLetters()): \Source = "s": \Replace = "эс"
AddElement(Pref_EnglishLetters()): \Source = "t": \Replace = "ти"
AddElement(Pref_EnglishLetters()): \Source = "u": \Replace = "ю"
AddElement(Pref_EnglishLetters()): \Source = "v": \Replace = "ви"
AddElement(Pref_EnglishLetters()): \Source = "w": \Replace = "да+блъю"
AddElement(Pref_EnglishLetters()): \Source = "x": \Replace = "экс"
AddElement(Pref_EnglishLetters()): \Source = "y": \Replace = "вай"
AddElement(Pref_EnglishLetters()): \Source = "z": \Replace = "зи"
EndWith
With Pref_RussianLetters()
AddElement(Pref_RussianLetters()): \Source = "б": \Replace = "бэ"
AddElement(Pref_RussianLetters()): \Source = "в": \Replace = "вэ"
AddElement(Pref_RussianLetters()): \Source = "к": \Replace = "ка"
AddElement(Pref_RussianLetters()): \Source = "с": \Replace = "эс"
AddElement(Pref_RussianLetters()): \Source = "ъ": \Replace = "твё+рдый знак"
AddElement(Pref_RussianLetters()): \Source = "ь": \Replace = "мя+хький знак"
EndWith
With Pref_EnglishPronunciation()
AddElement(Pref_EnglishPronunciation()): \Source = "j": \Replace = "дж"
AddElement(Pref_EnglishPronunciation()): \Source = "x": \Replace = "кс"
AddElement(Pref_EnglishPronunciation()): \Source = "y": \Replace = "ы"
EndWith
With Pref_SpecSymbols()
AddElement(Pref_SpecSymbols()) : \Source = "£" : \Replace = "фунт" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "€" : \Replace = "евро" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "¢" : \Replace = "центы" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "¥" : \Replace = "иена" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "₹" : \Replace = "рупия" : \SymbolMode = 1
AddElement(Pref_SpecSymbols()) : \Source = "₽" : \Replace = "рубль" : \SymbolMode = 1
AddElement(Pref_SpecSymbols()) : \Source = "₴" : \Replace = "гривна" : \SymbolMode = 1
AddElement(Pref_SpecSymbols()) : \Source = "圓" : \Replace = "юань" : \SymbolMode = 1
AddElement(Pref_SpecSymbols()) : \Source = "°" : \Replace = "градусов" : \SymbolMode = 1
AddElement(Pref_SpecSymbols()) : \Source = "„" : \Replace = "левая кавычка лапка" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "“" : \Replace = "правая кавычка лапка" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "”" : \Replace = "правая двойная кавычка" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "‘" : \Replace = "левая одиночная кавычка" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "’" : \Replace = "правая одиночная кавычка" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "–" : \Replace = "короткое тирэ" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "—" : \Replace = "длинное тирэ" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "‐" : \Replace = "дефис" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "●" : \Replace = "кружок" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "¨" : \Replace = "дириезис" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "‎" : \Replace = "метка слева на право" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "‏" : \Replace = "метка справа на лево" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "«" : \Replace = "левая кавычка ёлочка" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "»" : \Replace = "правая кавычка ёлочка" : \SymbolMode = 0
AddElement(Pref_SpecSymbols()) : \Source = "®" : \Replace = "зарегистрировано" : \SymbolMode = 1
AddElement(Pref_SpecSymbols()) : \Source = "™" : \Replace = "Торговая марка" : \SymbolMode = 1
AddElement(Pref_SpecSymbols()) : \Source = "©" : \Replace = "Авторское право" : \SymbolMode = 1
AddElement(Pref_SpecSymbols()) : \Source = "µ" : \Replace = "микро" : \SymbolMode = 1
AddElement(Pref_SpecSymbols()) : \Source = "•" : \Replace = "маркер" : \SymbolMode = 0
EndWith
EndIf
ClosePreferences()
Protected f = ReadFile(#PB_Any, NewfonConfigDir()+"ru_dict.dic", #PB_File_SharedRead)
If f
ReadStringFormat(f)
While Eof(f) = 0
Line$ = ReadString(f)
If Line$ And Mid(Line$, 1, 1) <> ";"
AddElement(Pref_UserDict())
With Pref_UserDict()
\Source = StringField(Line$, 1, Chr(32))
\Replace = StringField(Line$, 2, Chr(32))
EndWith
EndIf
Wend
CloseFile(f)
Else
AddElement(Pref_UserDict()) : Pref_UserDict()\Source = "труповозку" : Pref_UserDict()\Replace = "трупово+зку"
AddElement(Pref_UserDict()) : Pref_UserDict()\Source = "сервомеханизмов" : Pref_UserDict()\Replace = "сервомехани+змов"
AddElement(Pref_UserDict()) : Pref_UserDict()\Source = "самопровозглашенных" : Pref_UserDict()\Replace = "са+мо-провозглашё+нных"
AddElement(Pref_UserDict()) : Pref_UserDict()\Source = "ракетоплан" : Pref_UserDict()\Replace = "ракетопла+н"
AddElement(Pref_UserDict()) : Pref_UserDict()\Source = "посимвольном" : Pref_UserDict()\Replace = "поси+мвольном"
AddElement(Pref_UserDict()) : Pref_UserDict()\Source = "слово" : Pref_UserDict()\Replace = "сло+во"
EndIf
ProcedureReturn ConfigBeenOpened
EndProcedure

Procedure.i SaveConfig(Forced.b = #False)
Protected Path$ =  NewfonConfigDir()+"prefs.ini"
Protected DictPath$  = NewfonConfigDir()+"ru_dict.dic"
Protected isConfig.i = Bool(FileSize(Path$) >= 0)
If OpenPreferences(Path$, #PB_Preference_GroupSeparator, #PB_UTF8)
RemovePreferenceGroup("english_letters")
RemovePreferenceGroup("russian_letters")
RemovePreferenceGroup("english_pronunciation")
RemovePreferenceGroup("symbols")
PreferenceGroup("General")
RemovePreferenceKey("disable_decimal_separator")
SaveExtraParameters()
WritePreferenceInteger("pause", Pref_Pause)
 WritePreferenceLong("use_dictionary", Pref_UseDictionary)
WritePreferenceInteger("intonation", Pref_Intonation)
WritePreferenceInteger("silence_at_begin", Pref_SilenceAtBegin)
WritePreferenceInteger("silence_at_end", Pref_SilenceAtEnd)
PreferenceGroup("english_letters")
ForEach Pref_EnglishLetters()
WritePreferenceString(Pref_EnglishLetters()\Source, Pref_EnglishLetters()\Replace)
Next
PreferenceGroup("russian_letters")
ForEach Pref_RussianLetters()
WritePreferenceString(Pref_RussianLetters()\Source, Pref_RussianLetters()\Replace)
Next
PreferenceGroup("english_pronunciation")
ForEach Pref_EnglishPronunciation()
WritePreferenceString(Pref_EnglishPronunciation()\Source, Pref_EnglishPronunciation()\Replace)
Next
If ListSize(Pref_SpecSymbols())
PreferenceGroup("symbols")
PushListPosition(Pref_SpecSymbols())
ForEach Pref_SpecSymbols()
WritePreferenceString(Pref_SpecSymbols()\Source, Pref_SpecSymbols()\Replace+":"+Str(Pref_SpecSymbols()\SymbolMode))
Next
PopListPosition(Pref_SpecSymbols())
EndIf
ClosePreferences()
Protected df = CreateFile(#PB_Any, DictPath$)
If df
WriteStringFormat(df, #PB_UTF8)
PushListPosition(Pref_UserDict())
ForEach Pref_UserDict()
With Pref_UserDict()
If ListIndex(Pref_UserDict()) <> ListSize(Pref_UserDict())-1
WriteStringN(df, \Source+" "+\Replace)
Else
WriteString(df, \Source+" "+\Replace)
EndIf
EndWith
Next
PopListPosition(Pref_UserDict())
CloseFile(df)
Else
MessageRequester(trl("Ошибка"), trl(~"Не получилось записать словарь.\nОшибка записи в файл."), #PB_MessageRequester_Error)
ProcedureReturn #False
EndIf
If isConfig And Forced = #False
InformNewfon(#NFMSG_ReloadConfigs)
MessageRequester(trl("Успешно"), trl("Новые конфигурации применены!"), #PB_MessageRequester_Info)
EndIf
ProcedureReturn #True
Else
MessageRequester(trl("Ошибка"), trl(~"Не получилось применить новую конфигурацию...\nОшибка записи в файл."), #PB_MessageRequester_Error)
EndIf
ProcedureReturn #False
EndProcedure

Procedure.i CheckForbiddenStrings(Text.s,  Flags.i = #Null, AllowedChars.s = #Null$)
Result.a
For i.i = 1 To Len(Text)
Char.s = Mid(Text, i, 1)
Debug "Char: "+Char
*Char.Character = @Char
Expr.b = #Null
If Flags
Debug "Flags filled."
If Flags & #ChFS_AlphaLatin
Debug "Flag #ChFS_AlphaLatin been set."
Expr = Bool(Expr Or CharIsAlpha(*Char\c) = #alpha_latin)
Debug "Expr: "+Expr
EndIf
If Flags & #ChFS_AlphaCyrillic
Debug "Flag #ChFS_AlphaCyrillic been set."
Expr = Bool(Expr Or CharIsAlpha(*Char\c) = #alpha_Cyrillic)
Debug "Expr: "+Expr
EndIf
If Flags & #ChFS_Digits
Debug "Flag #ChFS_Digits been set."
Expr = Bool(Expr Or CharIsDigit(*Char\c))
Debug "Expr: "+Expr
EndIf
Else
Debug "No flags filled."
Expr = Bool(Not CharIsAlNum(*Char\c))
Debug "Expr: "+Expr
EndIf
If Not Expr
Result = i
If AllowedChars
Debug "Allowed chars have been set."
For k.i = 1 To Len(AllowedChars)
Sym.s = Mid(AllowedChars, k, 1)
Debug "checking for symbol "+Sym
*Sym.Character = @Sym
If *Char\c = *Sym\c
Debug "the char "+Char+" and "+Sym+" is equal."
Result = #Null
Debug "Breaking K for"
Break
EndIf
Next k
EndIf
If Result
Debug "Breaking I for"
Break
EndIf
EndIf
Next i
Debug "Procedure end"
ProcedureReturn Result
EndProcedure

Macro SelectAll(Gadget)
SendMessage_(GadgetID(Gadget), #EM_SETSEL, 0, -1)
EndMacro

Procedure.b AddSimpleDict(Where.b)
Title$ = #Null$
Protected.i DirtyCharSource, DirtyCharReplace
Select Where
Case #WF_EnglishLetters
Title$ = trl("Добавление произношения латиницы")
Case #WF_EnglishPronunciation
Title$ = trl("Добавление произношения латинских сочетаний")
Case #WF_RussianLetters
Title$ = trl("Добавление произношения кириллицы")
Case #WF_SpecSymbols
Title$ = trl("Добавление произношения символа")
Case #WF_UserDict
Title$ = trl("Добавление произношения пользовательского словаря")
EndSelect
OpenWindow(#AddSimpleDictWindow, #PB_Ignore, #PB_Ignore, 640, 240, Title$, #PB_Window_TitleBar|#PB_Window_WindowCentered, WindowID(#MainWindow))
Select Where
Case #WF_EnglishLetters, #WF_RussianLetters
TextGadget(#PB_Any, 10, 10, 160,30, trl(~"Буква:"))
Case #WF_EnglishPronunciation
TextGadget(#PB_Any, 10, 10, 160,30, trl(~"Сочетание:"))
Case #WF_UserDict
TextGadget(#PB_Any, 10, 10, 160,30, trl(~"Слово:"))
EndSelect
StringGadget(#AddSource_String, 171, 10, 50, 30, "")
GadgetToolTip(#AddSource_String, trl(~"Введите здесь значение, которое нужно исправить. Например, \"j\". Вводить нужно в нижнем регистре. Не используйте символов пунктуации."))
If Where = #WF_EnglishPronunciation
TextGadget(#PB_Any, 310, 10, 160, 30, trl(~"Читать как:"))
Else
TextGadget(#PB_Any, 310, 10, 160, 30, trl(~"Произносить как:"))
EndIf
StringGadget(#AddReplace_String, 471, 10, 50, 30, "")
GadgetToolTip(#AddReplace_String, trl(~"Введите здесь значение, на которое нужно исправить. Например, \"дже+й\". Вводить нужно в нижнем регистре. Не используйте символов пунктуации. Чтобы поставить ударение, используйте знак \"+\" (плюс) после ударной гласной."))
ButtonGadget(#OK_Btn, 50, 150, 100, 50, trl("Добавить"))
DisableGadget(#OK_Btn, #True)
ButtonGadget(#Cancel_Btn, 350, 150, 100, 50, trl("Отмена"))
SetActiveGadget(#AddSource_String)
Repeat
Protected Event = WaitWindowEvent()
If EventWindow() = #AddSimpleDictWindow
Select Event
Case #PB_Event_Gadget
Select EventGadget()
Case #AddSource_String
If EventType() = #PB_EventType_Focus
If DirtyCharSource
SendMessage_(GadgetID(#AddSource_String), #EM_SETSEL, DirtyCharSource-1, DirtyCharSource)
Else
SelectAll(#AddSource_String)
EndIf
ElseIf EventType() = #PB_EventType_Change
If GetGadgetText(#AddSource_String)
Select Where
Case #WF_EnglishLetters
DirtyCharSource = CheckForbiddenStrings(GetGadgetText(#AddSource_String), #ChFS_AlphaLatin)
Case #WF_RussianLetters
DirtyCharSource = CheckForbiddenStrings(GetGadgetText(#AddSource_String), #ChFS_AlphaCyrillic)
Case #WF_EnglishPronunciation
DirtyCharSource = CheckForbiddenStrings(GetGadgetText(#AddSource_String), #ChFS_AlphaLatin)
Case #WF_UserDict
DirtyCharSource = CheckForbiddenStrings(GetGadgetText(#AddSource_String), #ChFS_AlphaLatin|#ChFS_AlphaCyrillic)
EndSelect
If DirtyCharSource
NewMap vars.s()
vars("%char%") = Mid(GetGadgetText(#AddSource_String), DirtyCharSource, 1)
MessageBeep_(#MB_ICONERROR)
TextGadget(#Add_ErrorTip, 10, 41, 210,30, trlex(~"Недопустимый символ: \"%char%\"", vars()))
SendMessage_(GadgetID(#AddSource_String), #EM_SETSEL, DirtyCharSource-1, DirtyCharSource)
DisableGadget(#OK_Btn, #True)
FreeMap(vars())
EndIf
Else
DirtyCharSource = 0
EndIf
If GetGadgetText(#AddSource_String) And GetGadgetText(#AddReplace_String) And Not DirtyCharSource
DisableGadget(#OK_Btn, #False)
Else
DisableGadget(#OK_Btn, #True)
EndIf
EndIf
Case #AddReplace_String
If EventType() = #PB_EventType_Focus
If DirtyCharReplace
SendMessage_(GadgetID(#AddReplace_String), #EM_SETSEL, DirtyCharReplace-1, DirtyCharReplace)
Else
SelectAll(#AddReplace_String)
EndIf
ElseIf EventType() = #PB_EventType_Change
If GetGadgetText(#AddReplace_String)
Select Where
Case #WF_UserDict
DirtyCharReplace = CheckForbiddenStrings(GetGadgetText(#AddReplace_String), #ChFS_AlphaCyrillic, "+=-")
Default
DirtyCharReplace = CheckForbiddenStrings(GetGadgetText(#AddReplace_String), #ChFS_AlphaCyrillic, "+- ")
EndSelect
If DirtyCharReplace
NewMap vars.s()
vars("%char%") = Mid(GetGadgetText(#AddReplace_String), DirtyCharReplace, 1)
MessageBeep_(#MB_ICONERROR)
TextGadget(#Add_ErrorTip, 310, 41, 211,30, trlex(~"Недопустимый символ: \"%char%\"", vars()))
SendMessage_(GadgetID(#AddReplace_String), #EM_SETSEL, DirtyCharReplace-1, DirtyCharReplace)
DisableGadget(#OK_Btn, #True)
FreeMap(vars())
EndIf
Else
DirtyCharReplace = 0
EndIf
If GetGadgetText(#AddSource_String) And GetGadgetText(#AddReplace_String) And Not DirtyCharReplace
DisableGadget(#OK_Btn, #False)
Else
DisableGadget(#OK_Btn, #True)
EndIf
EndIf
Case #OK_Btn
If GetGadgetText(#AddSource_String) = ""
MessageRequester(trl("Ошибка"), trl("Не задано исходное значение произношения."), #PB_MessageRequester_Error)
Continue
EndIf
If GetGadgetText(#AddReplace_String) = ""
MessageRequester(trl("Ошибка"), trl("Не задана замена произношения."), #PB_MessageRequester_Error)
Continue
EndIf
If DirtyCharSource
NewMap vars.s()
vars("%char%") = Mid(GetGadgetText(#AddSource_String), DirtyCharSource, 1)
MessageRequester(trl("Ошибка"), trlex("В поле для задания что именно произносить присутствует один или несколько недопустимых символов. Для начала, удалите хотя бы %char%.", vars()), #PB_MessageRequester_Error)
FreeMap(vars())
Continue
EndIf
If DirtyCharReplace
NewMap vars.s()
vars("%char%") = Mid(GetGadgetText(#AddReplace_String), DirtyCharReplace, 1)
MessageRequester(trl("Ошибка"), trlex("В поле для задания как именно нужно произносить присутствует один или несколько недопустимых символов. Для начала, удалите хотя бы %char%.", vars()), #PB_MessageRequester_Error)
FreeMap(vars())
Continue
EndIf
Exists.a
Select Where
Case #WF_EnglishLetters
Exists = #False
PushListPosition(Pref_EnglishLetters())
ForEach Pref_EnglishLetters()
If LCase(Pref_EnglishLetters()\Source) = LCase(GetGadgetText(#AddSource_String))
MessageRequester(trl("Ошибка"), trl("Такое произношение уже задано."), #PB_MessageRequester_Error)
Exists = #True
Break
EndIf
Next
PopListPosition(Pref_EnglishLetters())
If Not Exists
LastElement(Pref_EnglishLetters())
AddElement(Pref_EnglishLetters())
Pref_EnglishLetters()\Source = LCase(GetGadgetText(#AddSource_String))
Pref_EnglishLetters()\Replace = LCase(GetGadgetText(#AddReplace_String))
EndIf
Case #WF_EnglishPronunciation
Exists = #False
PushListPosition(Pref_EnglishPronunciation())
ForEach Pref_EnglishPronunciation()
If LCase(Pref_EnglishPronunciation()\Source) = LCase(GetGadgetText(#AddSource_String))
MessageRequester(trl("Ошибка"), trl("Такое произношение уже задано."), #PB_MessageRequester_Error)
Exists = #True
Break
EndIf
Next
PopListPosition(Pref_EnglishPronunciation())
If Not Exists
LastElement(Pref_EnglishPronunciation())
AddElement(Pref_EnglishPronunciation())
Pref_EnglishPronunciation()\Source = LCase(GetGadgetText(#AddSource_String))
Pref_EnglishPronunciation()\Replace = LCase(GetGadgetText(#AddReplace_String))
EndIf
Case #WF_RussianLetters
Exists = #False
PushListPosition(Pref_RussianLetters())
ForEach Pref_RussianLetters()
If LCase(Pref_RussianLetters()\Source) = LCase(GetGadgetText(#AddSource_String))
MessageRequester(trl("Ошибка"), trl("Такое произношение уже задано."), #PB_MessageRequester_Error)
Exists = #True
Break
EndIf
Next
PopListPosition(Pref_RussianLetters())
If Not Exists
LastElement(Pref_RussianLetters())
AddElement(Pref_RussianLetters())
Pref_RussianLetters()\Source = LCase(GetGadgetText(#AddSource_String))
Pref_RussianLetters()\Replace = LCase(GetGadgetText(#AddReplace_String))
EndIf
Case #WF_UserDict
Exists = #False
PushListPosition(Pref_UserDict())
ForEach Pref_UserDict()
If LCase(Pref_UserDict()\Source) = LCase(GetGadgetText(#AddSource_String))
MessageRequester(trl("Ошибка"), trl("Такое произношение уже задано."), #PB_MessageRequester_Error)
Exists = #True
Break
EndIf
Next
PopListPosition(Pref_UserDict())
If Not Exists
LastElement(Pref_UserDict())
AddElement(Pref_UserDict())
Pref_UserDict()\Source = LCase(GetGadgetText(#AddSource_String))
Pref_UserDict()\Replace = LCase(GetGadgetText(#AddReplace_String))
EndIf
EndSelect
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn Exists!1
Case #Cancel_Btn
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn #False
EndSelect
Case #WM_KEYDOWN
If IsGadget(#Add_ErrorTip)
FreeGadget(#Add_ErrorTip)
EndIf
Select EventwParam()
Case #VK_ESCAPE
PostEvent(#PB_Event_Gadget, #AddSimpleDictWindow, #Cancel_Btn)
Case #VK_RETURN
PostEvent(#PB_Event_Gadget, #AddSimpleDictWindow, #OK_Btn)
EndSelect
Case #PB_Event_CloseWindow
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn #False
EndSelect
EndIf
ForEver
EndProcedure

Procedure.b AddSymbolDict()
OpenWindow(#AddSimpleDictWindow, #PB_Ignore, #PB_Ignore, 840, 240, trl("Добавление произношения символа"), #PB_Window_TitleBar|#PB_Window_WindowCentered, WindowID(#MainWindow))
TextGadget(#PB_Any, 10, 20, 80,20, trl(~"Символ:"))
StringGadget(#AddSource_String, 91, 20, 20, 20, "")
GadgetToolTip(#AddSource_String, trl(~"Введите здесь символ, которому нужно назначить правильное чтениеь. Например, \"%\"."))
TextGadget(#PB_Any, 113, 20, 160, 20, trl(~"Произносить как:"))
StringGadget(#AddReplace_String, 374, 20, 100, 20, "")
GadgetToolTip(#AddReplace_String, trl(~"Введите здесь как нужно произносить символ. Например, \"проце+нт\". Вводить нужно в нижнем регистре. Не используйте символов пунктуации. Чтобы поставить ударение, используйте знак \"+\" (плюс) после ударной гласной."))
TextGadget(#PB_Any, 475, 20, 120, 20, trl("Когда:"))
ComboBoxGadget(#Add_ModeCombo, 596, 20, 230, 20)
AddGadgetItem(#Add_ModeCombo, 0, trl("При посимвольном чтении"))
AddGadgetItem(#Add_ModeCombo, 1, trl("Всегда"))
SetGadgetState(#Add_ModeCombo, 0)
ButtonGadget(#OK_Btn, 50, 150, 100, 50, trl("Добавить"))
DisableGadget(#OK_Btn, #True)
ButtonGadget(#Cancel_Btn, 350, 150, 100, 50, trl("Отмена"))
SetActiveGadget(#AddSource_String)
Repeat
Protected Event = WaitWindowEvent()
If EventWindow() = #AddSimpleDictWindow
Select Event
Case #PB_Event_Gadget
Select EventGadget()
Case #AddSource_String
If EventType() = #PB_EventType_Focus
If DirtyCharSource
SendMessage_(GadgetID(#AddSource_String), #EM_SETSEL, DirtyCharSource-1, DirtyCharSource)
Else
SelectAll(#AddSource_String)
EndIf
ElseIf EventType() = #PB_EventType_Change
If GetGadgetText(#AddSource_String)
DirtyCharSource = CheckForbiddenStrings(GetGadgetText(#AddSource_String))
If DirtyCharSource
MessageBeep_(#MB_ICONERROR)
TextGadget(#Add_ErrorTip, 10, 41, 210,30, trl("Недопустимый символ!"))
SendMessage_(GadgetID(#AddSource_String), #EM_SETSEL, DirtyCharSource-1, DirtyCharSource)
DisableGadget(#OK_Btn, #True)
EndIf
Else
DirtyCharSource = 0
EndIf
If GetGadgetText(#AddSource_String) And GetGadgetText(#AddReplace_String) And Not DirtyCharSource
DisableGadget(#OK_Btn, #False)
Else
DisableGadget(#OK_Btn, #True)
EndIf
EndIf
Case #AddReplace_String
If EventType() = #PB_EventType_Focus
If DirtyCharReplace
SendMessage_(GadgetID(#AddReplace_String), #EM_SETSEL, DirtyCharReplace-1, DirtyCharReplace)
Else
SelectAll(#AddReplace_String)
EndIf
ElseIf EventType() = #PB_EventType_Change
If GetGadgetText(#AddReplace_String)
DirtyCharReplace = CheckForbiddenStrings(GetGadgetText(#AddReplace_String), #ChFS_AlphaCyrillic, "+- ")
If DirtyCharReplace
MessageBeep_(#MB_ICONERROR)
TextGadget(#Add_ErrorTip, 310, 41, 211,30, trl("Недопустимый символ!"))
SendMessage_(GadgetID(#AddReplace_String), #EM_SETSEL, DirtyCharReplace-1, DirtyCharReplace)
DisableGadget(#OK_Btn, #True)
EndIf
Else
DirtyCharReplace = 0
EndIf
If GetGadgetText(#AddSource_String) And GetGadgetText(#AddReplace_String) And Not DirtyCharReplace
DisableGadget(#OK_Btn, #False)
Else
DisableGadget(#OK_Btn, #True)
EndIf
EndIf
Case #OK_Btn
If GetGadgetText(#AddSource_String) = ""
MessageRequester(trl("Ошибка"), trl("Не задано исходное значение произношения."), #PB_MessageRequester_Error)
Continue
EndIf
If GetGadgetText(#AddReplace_String) = ""
MessageRequester(trl("Ошибка"), trl("Не задана замена произношения."), #PB_MessageRequester_Error)
Continue
EndIf
Exists.a
Exists = #False
ForEach Pref_SpecSymbols()
If Pref_SpecSymbols()\Source = GetGadgetText(#AddSource_String)
MessageRequester(trl("Ошибка"), trl("Такое произношение уже задано."), #PB_MessageRequester_Error)
Exists = #True
Break
EndIf
Next
If Not Exists
AddElement(Pref_SpecSymbols())
Pref_SpecSymbols()\Source = GetGadgetText(#AddSource_String)
Pref_SpecSymbols()\Replace = LCase(GetGadgetText(#AddReplace_String))
Pref_SpecSymbols()\SymbolMode = GetGadgetState(#Add_ModeCombo)
EndIf
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn Exists!1
Case #Cancel_Btn
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn #False
EndSelect
Case #WM_KEYDOWN
Select EventwParam()
Case #VK_ESCAPE
PostEvent(#PB_Event_Gadget, #AddSimpleDictWindow, #Cancel_Btn)
Case #VK_RETURN
PostEvent(#PB_Event_Gadget, #AddSimpleDictWindow, #OK_Btn)
EndSelect
Case #PB_Event_CloseWindow
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn #False
EndSelect
EndIf
ForEver
EndProcedure

Procedure.b EditSimpleDict(*Addr.SIMPLEDICT, Where.b)
NewMap vars.s()
vars("%letter%") = *Addr\Source
OpenWindow(#AddSimpleDictWindow, #PB_Ignore, #PB_Ignore, 640, 240, trlex(~"Редактирование произношения \"%letter%\"", vars()), #PB_Window_TitleBar|#PB_Window_WindowCentered, WindowID(#MainWindow))
FreeMap(vars())
Select Where
Case #WF_EnglishLetters, #WF_RussianLetters
TextGadget(#PB_Any, 10, 10, 160,30, trl(~"Буква:"))
Case #WF_EnglishPronunciation
TextGadget(#PB_Any, 10, 10, 160,30, trl(~"Сочетание:"))
Case #WF_UserDict
TextGadget(#PB_Any, 10, 10, 160,30, trl(~"Слово:"))
EndSelect
StringGadget(#AddSource_String, 171, 10, 50, 30, *Addr\Source)
GadgetToolTip(#AddSource_String, trl(~"Введите здесь значение, которое нужно исправить. Например, \"j\". Вводить нужно в нижнем регистре. Не используйте символов пунктуации."))
If Where = #WF_EnglishPronunciation
TextGadget(#PB_Any, 310, 10, 160, 30, trl(~"Читать как:"))
Else
TextGadget(#PB_Any, 310, 10, 160, 30, trl(~"Произносить как:"))
EndIf
StringGadget(#AddReplace_String, 471, 10, 50, 30, *Addr\Replace)
GadgetToolTip(#AddReplace_String, trl(~"Введите здесь значение, на которое нужно исправить. Например, \"дже+й\". Вводить нужно в нижнем регистре. Не используйте символов пунктуации. Чтобы поставить ударение, используйте знак \"+\" (плюс) после ударной гласной."))
ButtonGadget(#OK_Btn, 50, 150, 100, 50, trl("Сохранить"))
If GetGadgetText(#AddSource_String) = #Null$ And GetGadgetText(#AddReplace_String) = #Null$
DisableGadget(#OK_Btn, #True)
EndIf
ButtonGadget(#Cancel_Btn, 350, 150, 100, 50, trl("Отмена"))
SetActiveGadget(#AddSource_String)
Repeat
Protected Event = WaitWindowEvent()
If EventWindow() = #AddSimpleDictWindow
Select Event
Case #PB_Event_Gadget
Select EventGadget()
Case #AddSource_String
If EventType() = #PB_EventType_Focus
If DirtyCharSource
SendMessage_(GadgetID(#AddSource_String), #EM_SETSEL, DirtyCharSource-1, DirtyCharSource)
Else
SelectAll(#AddSource_String)
EndIf
ElseIf EventType() = #PB_EventType_Change
If GetGadgetText(#AddSource_String)
Select Where
Case #WF_EnglishLetters
DirtyCharSource = CheckForbiddenStrings(GetGadgetText(#AddSource_String), #ChFS_AlphaLatin)
Case #WF_RussianLetters
DirtyCharSource = CheckForbiddenStrings(GetGadgetText(#AddSource_String), #ChFS_AlphaCyrillic)
Case #WF_EnglishPronunciation
DirtyCharSource = CheckForbiddenStrings(GetGadgetText(#AddSource_String), #ChFS_AlphaLatin)
Case #WF_UserDict
DirtyCharSource = CheckForbiddenStrings(GetGadgetText(#AddSource_String), #ChFS_AlphaLatin|#ChFS_AlphaCyrillic)
EndSelect
If DirtyCharSource
MessageBeep_(#MB_ICONERROR)
TextGadget(#Add_ErrorTip, 10, 41, 210,30, trl("Недопустимый символ!"))
SendMessage_(GadgetID(#AddSource_String), #EM_SETSEL, DirtyCharSource-1, DirtyCharSource)
DisableGadget(#OK_Btn, #True)
EndIf
Else
DirtyCharSource = 0
EndIf
If GetGadgetText(#AddSource_String) And GetGadgetText(#AddReplace_String) And Not DirtyCharSource
DisableGadget(#OK_Btn, #False)
Else
DisableGadget(#OK_Btn, #True)
EndIf
EndIf
Case #AddReplace_String
If EventType() = #PB_EventType_Focus
If DirtyCharReplace
SendMessage_(GadgetID(#AddReplace_String), #EM_SETSEL, DirtyCharReplace-1, DirtyCharReplace)
Else
SelectAll(#AddReplace_String)
EndIf
ElseIf EventType() = #PB_EventType_Change
If GetGadgetText(#AddReplace_String)
Select Where
Case #WF_UserDict
DirtyCharReplace = CheckForbiddenStrings(GetGadgetText(#AddReplace_String), #ChFS_AlphaCyrillic, "+=-")
Default
DirtyCharReplace = CheckForbiddenStrings(GetGadgetText(#AddReplace_String), #ChFS_AlphaCyrillic, "+- ")
EndSelect
If DirtyCharReplace
MessageBeep_(#MB_ICONERROR)
TextGadget(#Add_ErrorTip, 310, 41, 211,30, trl("Недопустимый символ!"))
SendMessage_(GadgetID(#AddReplace_String), #EM_SETSEL, DirtyCharReplace-1, DirtyCharReplace)
DisableGadget(#OK_Btn, #True)
EndIf
Else
DirtyCharReplace = 0
EndIf
If GetGadgetText(#AddSource_String) And GetGadgetText(#AddReplace_String) And Not DirtyCharReplace
DisableGadget(#OK_Btn, #False)
Else
DisableGadget(#OK_Btn, #True)
EndIf
EndIf
Case #OK_Btn
If GetGadgetText(#AddSource_String) = ""
MessageRequester(trl("Ошибка"), trl("Не задано исходное значение произношения."), #PB_MessageRequester_Error)
Continue
EndIf
If GetGadgetText(#AddReplace_String) = ""
MessageRequester(trl("Ошибка"), trl("Не задана замена произношения."), #PB_MessageRequester_Error)
Continue
EndIf
*Addr\Source = LCase(GetGadgetText(#AddSource_String))
*Addr\Replace = LCase(GetGadgetText(#AddReplace_String))
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn #True
Case #Cancel_Btn
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn #False
EndSelect
Case #WM_KEYDOWN
Select EventwParam()
Case #VK_ESCAPE
PostEvent(#PB_Event_Gadget, #AddSimpleDictWindow, #Cancel_Btn)
Case #VK_RETURN
PostEvent(#PB_Event_Gadget, #AddSimpleDictWindow, #OK_Btn)
EndSelect
Case #PB_Event_CloseWindow
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn #False
EndSelect
EndIf
ForEver
EndProcedure

Procedure.b EditSymbolDict(*Addr.SYMBOLDICT)
NewMap vars.s()
vars("%letter%") = *Addr\Source
OpenWindow(#AddSimpleDictWindow, #PB_Ignore, #PB_Ignore, 840, 240, trlex(~"Редактирование произношения символа \"%letter%\"", vars()), #PB_Window_TitleBar|#PB_Window_WindowCentered, WindowID(#MainWindow))
FreeMap(vars())
TextGadget(#PB_Any, 10, 20, 80,20, trl(~"Символ:"))
StringGadget(#AddSource_String, 91, 20, 20, 20, *Addr\Source)
GadgetToolTip(#AddSource_String, trl(~"Введите здесь символ, которому нужно назначить правильное чтениеь. Например, \"%\"."))
TextGadget(#PB_Any, 113, 20, 160, 20, trl(~"Произносить как:"))
StringGadget(#AddReplace_String, 374, 20, 100, 20, *Addr\Replace)
GadgetToolTip(#AddReplace_String, trl(~"Введите здесь как нужно произносить символ. Например, \"проце+нт\". Вводить нужно в нижнем регистре. Не используйте символов пунктуации. Чтобы поставить ударение, используйте знак \"+\" (плюс) после ударной гласной."))
TextGadget(#PB_Any, 475, 20, 120, 20, trl("Когда:"))
ComboBoxGadget(#Add_ModeCombo, 596, 20, 230, 20)
AddGadgetItem(#Add_ModeCombo, 0, trl("При посимвольном чтении"))
AddGadgetItem(#Add_ModeCombo, 1, trl("Всегда"))
SetGadgetState(#Add_ModeCombo, *Addr\SymbolMode)
ButtonGadget(#OK_Btn, 50, 150, 100, 50, trl("Сохранить"))
If GetGadgetText(#AddSource_String) = #Null$ And GetGadgetText(#AddReplace_String) = #Null$
DisableGadget(#OK_Btn, #True)
EndIf
ButtonGadget(#Cancel_Btn, 350, 150, 100, 50, trl("Отмена"))
SetActiveGadget(#AddSource_String)
Repeat
Protected Event = WaitWindowEvent()
If EventWindow() = #AddSimpleDictWindow
Select Event
Case #PB_Event_Gadget
Select EventGadget()
Case #AddSource_String
If EventType() = #PB_EventType_Focus
If DirtyCharSource
SendMessage_(GadgetID(#AddSource_String), #EM_SETSEL, DirtyCharSource-1, DirtyCharSource)
Else
SelectAll(#AddSource_String)
EndIf
ElseIf EventType() = #PB_EventType_Change
If GetGadgetText(#AddSource_String)
DirtyCharSource = CheckForbiddenStrings(GetGadgetText(#AddSource_String))
If DirtyCharSource
MessageBeep_(#MB_ICONERROR)
TextGadget(#Add_ErrorTip, 10, 41, 210,30, trl("Недопустимый символ!"))
SendMessage_(GadgetID(#AddSource_String), #EM_SETSEL, DirtyCharSource-1, DirtyCharSource)
DisableGadget(#OK_Btn, #True)
EndIf
Else
DirtyCharSource = 0
EndIf
If GetGadgetText(#AddSource_String) And GetGadgetText(#AddReplace_String) And Not DirtyCharSource
DisableGadget(#OK_Btn, #False)
Else
DisableGadget(#OK_Btn, #True)
EndIf
EndIf
Case #AddReplace_String
If EventType() = #PB_EventType_Focus
If DirtyCharReplace
SendMessage_(GadgetID(#AddReplace_String), #EM_SETSEL, DirtyCharReplace-1, DirtyCharReplace)
Else
SelectAll(#AddReplace_String)
EndIf
ElseIf EventType() = #PB_EventType_Change
If GetGadgetText(#AddReplace_String)
DirtyCharReplace = CheckForbiddenStrings(GetGadgetText(#AddReplace_String), #ChFS_AlphaCyrillic, "+- ")
If DirtyCharReplace
MessageBeep_(#MB_ICONERROR)
TextGadget(#Add_ErrorTip, 310, 41, 211,30, trl("Недопустимый символ!"))
SendMessage_(GadgetID(#AddReplace_String), #EM_SETSEL, DirtyCharReplace-1, DirtyCharReplace)
DisableGadget(#OK_Btn, #True)
EndIf
Else
DirtyCharReplace = 0
EndIf
If GetGadgetText(#AddSource_String) And GetGadgetText(#AddReplace_String) And Not DirtyCharReplace
DisableGadget(#OK_Btn, #False)
Else
DisableGadget(#OK_Btn, #True)
EndIf
EndIf
Case #OK_Btn
If GetGadgetText(#AddSource_String) = ""
MessageRequester(trl("Ошибка"), trl("Не задано исходное значение произношения."), #PB_MessageRequester_Error)
Continue
EndIf
If GetGadgetText(#AddReplace_String) = ""
MessageRequester(trl("Ошибка"), trl("Не задана замена произношения."), #PB_MessageRequester_Error)
Continue
EndIf
*Addr\Source = GetGadgetText(#AddSource_String)
*Addr\Replace = LCase(GetGadgetText(#AddReplace_String))
*Addr\SymbolMode = GetGadgetState(#Add_ModeCombo)
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn #True
Case #Cancel_Btn
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn #False
EndSelect
Case #WM_KEYDOWN
Select EventwParam()
Case #VK_ESCAPE
PostEvent(#PB_Event_Gadget, #AddSimpleDictWindow, #Cancel_Btn)
Case #VK_RETURN
PostEvent(#PB_Event_Gadget, #AddSimpleDictWindow, #OK_Btn)
EndSelect
Case #PB_Event_CloseWindow
CloseWindow(#AddSimpleDictWindow)
ProcedureReturn #False
EndSelect
EndIf
ForEver
EndProcedure

Procedure InformNewfon(MSG.i)
  ; The SAPI engine reloads prefs.ini before every utterance.
EndProcedure


; Noninteractive persistence test, isolated by an explicit config directory.
If LCase(ProgramParameter()) = "--test-roundtrip" And GetEnvironmentVariable("NEWFON_CONFIG_DIR") <> ""
  EnsurePrefs()
  If LoadConfig() = 0 : End 2 : EndIf
  If SaveConfig(#True) = 0 : End 3 : EndIf
  CloseInstance(AppInstance)
  End 0
EndIf

If AppInstance
RunAfterSetup.a = Bool(LCase(ProgramParameter()) = "-runaftersetup")
EnsurePrefs()
ConfigLoaded = LoadConfig()
If ConfigLoaded And RunAfterSetup
CloseInstance(AppInstance)
End
EndIf

OpenWindow(#MainWindow, 0, 0, 1200, 685, trl("Настройки Newfon SAPI"), #PB_Window_SystemMenu|#PB_Window_TitleBar)
FrameGadget(#PB_Any, 0, 20, 1180, 310, trl("Основные настройки"))
CheckBoxGadget(#UsePause_Check, 300, 40, 261, 20, trl("Использовать заданные паузы"))
GadgetToolTip(#UsePause_Check, trl("При снятой галочке, Newfon будет подбирать паузы между знаками препинания, а также при разделении больших фрагментов текста в зависимости от скорости. При установленной же галочке, паузы можно регулировать самому от 0 до 100."))
TextGadget(#PB_Any, 670, 43, 0, 0, trl("Паузы между словами и фрагментами:"))
TrackBarGadget(#Pause_Track, 662, 40, 150, 20, 0, 100)
Select Pref_Pause
Case -1
SetGadgetState(#UsePause_Check, #False)
DisableGadget(#Pause_Track, #True)
Default
SetGadgetState(#UsePause_Check, #True)
DisableGadget(#Pause_Track, #False)
SetGadgetState(#Pause_Track, Pref_Pause)
EndSelect
TextGadget(#PB_Any, 300, 61, 260, 20, trl("Интонация:"))
TrackBarGadget(#Intonation_Track, 662, 61, 150, 20, 0, 100)
GadgetToolTip(#Intonation_Track, trl("Можно задать интенсивность интонации синтезатора: 0 - монотонно, 100 - очень выразительно."))
SetGadgetState(#Intonation_Track, Pref_Intonation)
TextGadget(#PB_Any, 10, 61, 80, 20, trl("Словарь:"))
ComboBoxGadget(#UseDictionary_Combo, 91, 61, 319, 20)
AddGadgetItem(#UseDictionary_Combo, 0, trl("Выключен"))
AddGadgetItem(#UseDictionary_Combo, 1, trl("Только встроенный"))
AddGadgetItem(#UseDictionary_Combo, 2, trl("Встроенный и пользовательский"))
AddGadgetItem(#UseDictionary_Combo, 3, trl("Только пользовательский"))
GadgetToolTip(#UseDictionary_Combo, trl("Позволяет включить словари правильного произношения и ударений для слов. Можно включить только системный, включить системный и пользовательский, или же вообще отключить все словари."))
SetGadgetState(#UseDictionary_Combo, Pref_UseDictionary)
TextGadget(#PB_Any, 10, 82, 150, 20, trl("Пауза в начале:"))
TrackBarGadget(#SilenceAtBegin_track, 161, 82, 239, 20, 0, 250)
GadgetToolTip(#SilenceAtBegin_track, trl("Позволяет задать паузу непосредственно перед началом синтеза. Полезно, если приложение допускает ошибки и первые буквы съедаются."))
SetGadgetState(#SilenceAtBegin_track, Pref_SilenceAtBegin)
TextGadget(#PB_Any, 400, 82, 150, 20, trl("Пауза в конце:"))
TrackBarGadget(#SilenceAtEnd_track, 551, 82, 239, 20, 0, 250)
GadgetToolTip(#SilenceAtEnd_track, trl("Позволяет задать паузу непосредственно в конце синтеза. Полезно, если приложение допускает ошибки и последние буквы съедаются."))
SetGadgetState(#SilenceAtEnd_track, Pref_SilenceAtEnd)
NewfonParameterGadgets()
ButtonGadget(#Docs_Btn, 800, 0, 140, 20, trl("Документация"))
ButtonGadget(#Apply_Btn, 980, 0, 100, 20, trl("Применить"))
FrameGadget(#PB_Any, 0, 157, 1200, 459, trl("Произношения"))
TabsAtBottom = PanelGadget(#PB_Any, 10, 176, 1180, 438)
AddGadgetItem(TabsAtBottom, #WF_EnglishLetters, trl("Латиница"))
ListIconGadget(#EnglishLetters_ListIcon, 20, 141, 800, 375, trl("Буква"), 400, #PB_ListIcon_FullRowSelect)
AddGadgetColumn(#EnglishLetters_ListIcon, 1, trl("Произносить как"), 400)
ForEach Pref_EnglishLetters()
AddGadgetItem(#EnglishLetters_ListIcon, -1, Pref_EnglishLetters()\Source+Chr(10)+Pref_EnglishLetters()\Replace)
Next
AddGadgetItem(TabsAtBottom, #WF_RussianLetters, trl("Кириллица"))
ListIconGadget(#RussianLetters_ListIcon, 20, 141, 800, 375, trl("Буква"), 400, #PB_ListIcon_FullRowSelect)
AddGadgetColumn(#RussianLetters_ListIcon, 1, trl("Произносить как"), 400)
ForEach Pref_RussianLetters()
AddGadgetItem(#RussianLetters_ListIcon, -1, Pref_RussianLetters()\Source+Chr(10)+Pref_RussianLetters()\Replace)
Next
AddGadgetItem(TabsAtBottom, #WF_EnglishPronunciation, trl("Латинские сочетания"))
ListIconGadget(#EnglishPronunciation_ListIcon, 20, 141, 800, 350, trl("Буква"), 400, #PB_ListIcon_FullRowSelect)
AddGadgetColumn(#EnglishPronunciation_ListIcon, 1, trl("Читать как"), 400)
ForEach Pref_EnglishPronunciation()
AddGadgetItem(#EnglishPronunciation_ListIcon, -1, Pref_EnglishPronunciation()\Source+Chr(10)+Pref_EnglishPronunciation()\Replace)
Next
AddGadgetItem(TabsAtBottom, #WF_SpecSymbols, trl("Символы"))
ListIconGadget(#SpecSymbols_ListIcon, 20, 141, 800, 375, trl("Символ"), 10, #PB_ListIcon_FullRowSelect)
AddGadgetColumn(#SpecSymbols_ListIcon, 1, trl("Произносить как"), 300)
AddGadgetColumn(#SpecSymbols_ListIcon, 2, trl("Когда"), 400)
ForEach Pref_SpecSymbols()
State$ = ""
Select Pref_SpecSymbols()\SymbolMode
Case 0
State$ = "При посимвольном чтении"
Case 1
State$ = "Всегда"
EndSelect
AddGadgetItem(#SpecSymbols_ListIcon, -1, Pref_SpecSymbols()\Source+Chr(10)+Pref_SpecSymbols()\Replace+Chr(10)+State$)
Next
If Pref_UseDictionary >= 2
AddGadgetItem(TabsAtBottom, #WF_UserDict, trl("Словарь"))
ListIconGadget(#UserDict_ListIcon, 20, 141, 800, 375, trl("Исходное"), 400, #PB_ListIcon_FullRowSelect)
AddGadgetColumn(#UserDict_ListIcon, 1, trl("Произносить как"), 400)
ForEach Pref_UserDict()
AddGadgetItem(#UserDict_ListIcon, -1, Pref_UserDict()\Source+Chr(10)+Pref_UserDict()\Replace)
Next
EndIf
CloseGadgetList()
ButtonGadget(#AddEntry_Btn, 100, 625, 100, 20, trl("Добавить"))
ButtonGadget(#EditEntry_Btn, 400, 625, 100, 20, trl("Редактировать"))
ButtonGadget(#DeleteEntry_Btn, 600, 625, 100, 20, trl("Удалить"))
DisableGadget(#EditEntry_Btn, #True)
DisableGadget(#DeleteEntry_Btn, #True)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control|#PB_Shortcut_S, #PMI_ApplyConfigs)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Control|#PB_Shortcut_D, #PMI_AddDictEntry)
AddKeyboardShortcut(#MainWindow, #PB_Shortcut_F1, #PMI_Docs)
If CreatePopupMenu(#MNU_Context1)
MenuItem(#MI_Add, trl("Доб&авить..."))
MenuItem(#MI_Edit, trl("Р&едактировать..."))
MenuItem(#MI_Delete, trl("У&далить..."))
EndIf
SetActiveGadget(#NF_SampleRate)
Repeat
Event = WaitWindowEvent()
If Event = #PB_Event_Gadget
Select EventGadget()
Case #NF_SampleRate, #NF_Multiplier, #NF_Algorithm, #NF_Acceleration, #NF_Legacy, #NF_DecimalPoint, #NF_DecimalComma
NF_SampleRate = NF_SliderToRate(GetGadgetState(#NF_SampleRate))
NF_Multiplier = Val(GetGadgetText(#NF_Multiplier))
NF_Algorithm = GetGadgetState(#NF_Algorithm)
NF_Acceleration = GetGadgetState(#NF_Acceleration)
NF_Legacy = GetGadgetState(#NF_Legacy)
; The checkboxes forbid the separator, prefs.ini stores whether it is used.
NF_DecimalPoint = 1-GetGadgetState(#NF_DecimalPoint)
NF_DecimalComma = 1-GetGadgetState(#NF_DecimalComma)
ConfigsChanged = #True
Case #UseDictionary_Combo
PreviousValue.i = Pref_UseDictionary
Pref_UseDictionary = GetGadgetState(#UseDictionary_Combo)
ConfigsChanged = #True
If Pref_UseDictionary >= 2 And PreviousValue < 2
OpenGadgetList(TabsAtBottom)
AddGadgetItem(TabsAtBottom, #WF_UserDict, trl("Словарь"))
ListIconGadget(#UserDict_ListIcon, 20, 141, 800, 375, trl("Исходное"), 400, #PB_ListIcon_FullRowSelect)
AddGadgetColumn(#UserDict_ListIcon, 1, trl("Произносить как"), 400)
ForEach Pref_UserDict()
AddGadgetItem(#UserDict_ListIcon, -1, Pref_UserDict()\Source+Chr(10)+Pref_UserDict()\Replace)
Next
ElseIf Pref_UseDictionary < 2
RemoveGadgetItem(TabsAtBottom, #WF_UserDict)
EndIf
Case #UsePause_Check
Select GetGadgetState(#UsePause_Check)
Case #True
DisableGadget(#Pause_Track, #False)
Pref_Pause = GetGadgetState(#Pause_Track)
Case #False
DisableGadget(#Pause_Track, #True)
Pref_Pause = -1
EndSelect
ConfigsChanged = #True
Case#Pause_Track
  Pref_Pause = GetGadgetState(#Pause_Track)
ConfigsChanged = #True
Case #Intonation_Track
Pref_Intonation = GetGadgetState(#Intonation_Track)
ConfigsChanged = #True
Case #SilenceAtBegin_track
Pref_SilenceAtBegin = GetGadgetState(#SilenceAtBegin_track)
ConfigsChanged = #True
Case #SilenceAtEnd_track
Pref_SilenceAtEnd = GetGadgetState(#SilenceAtEnd_track)
ConfigsChanged = #True
Case #EnglishLetters_ListIcon
Select EventType()
 Case #PB_EventType_Change
If ListSize(Pref_EnglishLetters()) And GetGadgetState(#EnglishLetters_ListIcon) >= 0
SelectElement(Pref_EnglishLetters(), GetGadgetState(#EnglishLetters_ListIcon))
DisableGadget(#EditEntry_Btn, #False)
DisableGadget(#DeleteEntry_Btn, #False)
Else
DisableGadget(#EditEntry_Btn, #True)
DisableGadget(#DeleteEntry_Btn, #True)
EndIf
Case #PB_EventType_RightClick
If GetGadgetState(#EnglishLetters_ListIcon) >= 0
If ListSize(Pref_EnglishLetters())
SelectElement(Pref_EnglishLetters(), GetGadgetState(#EnglishLetters_ListIcon))
EndIf
DisplayPopupMenu(#MNU_Context1, WindowID(#MainWindow), 130, 202)
EndIf
EndSelect
Case #RussianLetters_ListIcon
Select EventType()
Case #PB_EventType_Change
If ListSize(Pref_RussianLetters()) And GetGadgetState(#RussianLetters_ListIcon) >= 0
SelectElement(Pref_RussianLetters(), GetGadgetState(#RussianLetters_ListIcon))
DisableGadget(#EditEntry_Btn, #False)
DisableGadget(#DeleteEntry_Btn, #False)
Else
DisableGadget(#EditEntry_Btn, #True)
DisableGadget(#DeleteEntry_Btn, #True)
EndIf
 Case #PB_EventType_RightClick
If ListSize(Pref_RussianLetters()) And GetGadgetState(#RussianLetters_ListIcon) >= 0
SelectElement(Pref_RussianLetters(), GetGadgetState(#RussianLetters_ListIcon))
EndIf
DisplayPopupMenu(#MNU_Context1, WindowID(#MainWindow), 30, 152)
EndSelect
Case #EnglishPronunciation_ListIcon
Select EventType()
Case #PB_EventType_Change
If ListSize(Pref_EnglishPronunciation()) And GetGadgetState(#EnglishPronunciation_ListIcon) >= 0
SelectElement(Pref_EnglishPronunciation(), GetGadgetState(#EnglishPronunciation_ListIcon))
DisableGadget(#EditEntry_Btn, #False)
DisableGadget(#DeleteEntry_Btn, #False)
Else
DisableGadget(#EditEntry_Btn, #True)
DisableGadget(#DeleteEntry_Btn, #True)
EndIf
Case #PB_EventType_RightClick
If ListSize(Pref_EnglishPronunciation()) And GetGadgetState(#EnglishPronunciation_ListIcon) >= 0
SelectElement(Pref_EnglishPronunciation(), GetGadgetState(#EnglishPronunciation_ListIcon))
EndIf
DisplayPopupMenu(#MNU_Context1, WindowID(#MainWindow), 30, 152)
EndSelect
Case #SpecSymbols_ListIcon
Select EventType()
Case #PB_EventType_Change
If ListSize(Pref_SpecSymbols()) And GetGadgetState(#SpecSymbols_ListIcon) >= 0
SelectElement(Pref_SpecSymbols(), GetGadgetState(#SpecSymbols_ListIcon))
DisableGadget(#EditEntry_Btn, #False)
DisableGadget(#DeleteEntry_Btn, #False)
Else
DisableGadget(#EditEntry_Btn, #True)
DisableGadget(#DeleteEntry_Btn, #True)
EndIf
Case #PB_EventType_RightClick
If ListSize(Pref_SpecSymbols()) And GetGadgetState(#SpecSymbols_ListIcon) >= 0
SelectElement(Pref_SpecSymbols(), GetGadgetState(#SpecSymbols_ListIcon))
EndIf
DisplayPopupMenu(#MNU_Context1, WindowID(#MainWindow), 30, 152)
EndSelect
Case #UserDict_ListIcon
Select EventType()
 Case #PB_EventType_Change
If ListSize(Pref_UserDict()) And GetGadgetState(#UserDict_ListIcon) >= 0
SelectElement(Pref_UserDict(), GetGadgetState(#UserDict_ListIcon))
DisableGadget(#EditEntry_Btn, #False)
DisableGadget(#DeleteEntry_Btn, #False)
Else
DisableGadget(#EditEntry_Btn, #True)
DisableGadget(#DeleteEntry_Btn, #True)
EndIf
Case #PB_EventType_RightClick
If ListSize(Pref_UserDict()) And GetGadgetState(#UserDict_ListIcon) >= 0
SelectElement(Pref_UserDict(), GetGadgetState(#UserDict_ListIcon))
EndIf
DisplayPopupMenu(#MNU_Context1, WindowID(#MainWindow), 30, 152)
EndSelect
Case TabsAtBottom
ActiveGadget.i
Select GetGadgetState(TabsAtBottom)
Case #WF_EnglishLetters
ActiveGadget = #EnglishLetters_ListIcon
Case #WF_EnglishPronunciation
ActiveGadget = #EnglishPronunciation_ListIcon
Case #WF_RussianLetters
ActiveGadget = #RussianLetters_ListIcon
Case #WF_SpecSymbols
ActiveGadget = #SpecSymbols_ListIcon
Case #WF_UserDict
ActiveGadget = #UserDict_ListIcon
Default
ActiveGadget = #Null
EndSelect
PostEvent(#PB_Event_Gadget, #MainWindow, ActiveGadget, #PB_EventType_Change)
Case #AddEntry_Btn
Select GetGadgetState(TabsAtBottom)
Case #WF_EnglishLetters
If AddSimpleDict(#WF_EnglishLetters)
ConfigsChanged = #True
ClearGadgetItems(#EnglishLetters_ListIcon)
ForEach Pref_EnglishLetters()
AddGadgetItem(#EnglishLetters_ListIcon, -1, Pref_EnglishLetters()\Source+Chr(10)+Pref_EnglishLetters()\Replace)
Next
SetGadgetState(#EnglishLetters_ListIcon, ListIndex(Pref_EnglishLetters()))
EndIf
Case #WF_RussianLetters
If AddSimpleDict(#WF_RussianLetters)
ConfigsChanged = #True
ClearGadgetItems(#RussianLetters_ListIcon)
ForEach Pref_RussianLetters()
AddGadgetItem(#RussianLetters_ListIcon, -1, Pref_RussianLetters()\Source+Chr(10)+Pref_RussianLetters()\Replace)
Next
SetGadgetState(#RussianLetters_ListIcon, ListIndex(Pref_RussianLetters()))
EndIf
Case #WF_EnglishPronunciation
If AddSimpleDict(#WF_EnglishPronunciation)
ConfigsChanged = #True
ClearGadgetItems(#EnglishPronunciation_ListIcon)
ForEach Pref_EnglishPronunciation()
AddGadgetItem(#EnglishPronunciation_ListIcon, -1, Pref_EnglishPronunciation()\Source+Chr(10)+Pref_EnglishPronunciation()\Replace)
Next
SetGadgetState(#EnglishPronunciation_ListIcon, ListIndex(Pref_EnglishPronunciation()))
EndIf
Case #WF_SpecSymbols
If AddSymbolDict()
ConfigsChanged = #True
ClearGadgetItems(#SpecSymbols_ListIcon)
ForEach Pref_SpecSymbols()
State$ = ""
Select Pref_SpecSymbols()\SymbolMode
Case 0
State$ = "При посимвольном чтении"
Case 1
State$ = "Всегда"
EndSelect
AddGadgetItem(#SpecSymbols_ListIcon, -1, Pref_SpecSymbols()\Source+Chr(10)+Pref_SpecSymbols()\Replace+Chr(10)+State$)
Next
SetGadgetState(#SpecSymbols_ListIcon, ListIndex(Pref_SpecSymbols()))
EndIf
Case #WF_UserDict
If AddSimpleDict(#WF_UserDict)
ConfigsChanged = #True
ClearGadgetItems(#UserDict_ListIcon)
ForEach Pref_UserDict()
AddGadgetItem(#UserDict_ListIcon, -1, Pref_UserDict()\Source+Chr(10)+Pref_UserDict()\Replace)
Next
SetGadgetState(#UserDict_ListIcon, ListIndex(Pref_UserDict()))
EndIf
EndSelect
Case #EditEntry_Btn
ActiveGadget.i
Select GetGadgetState(TabsAtBottom)
Case #WF_EnglishLetters
ActiveGadget = #EnglishLetters_ListIcon
Case #WF_EnglishPronunciation
ActiveGadget = #EnglishPronunciation_ListIcon
Case #WF_RussianLetters
ActiveGadget = #RussianLetters_ListIcon
Case #WF_SpecSymbols
ActiveGadget = #SpecSymbols_ListIcon
Case #WF_UserDict
ActiveGadget = #UserDict_ListIcon
Default
ActiveGadget = #Null
EndSelect
If GetGadgetState(ActiveGadget) >= 0
Select ActiveGadget
Case #EnglishLetters_ListIcon
If EditSimpleDict(@Pref_EnglishLetters(), #WF_EnglishLetters)
ConfigsChanged = #True
PushListPosition(Pref_EnglishLetters())
ClearGadgetItems(#EnglishLetters_ListIcon)
ForEach Pref_EnglishLetters()
AddGadgetItem(#EnglishLetters_ListIcon, -1, Pref_EnglishLetters()\Source+Chr(10)+Pref_EnglishLetters()\Replace)
Next
PopListPosition(Pref_EnglishLetters())
SetGadgetState(#EnglishLetters_ListIcon, ListIndex(Pref_EnglishLetters()))
EndIf
Case #RussianLetters_ListIcon
If EditSimpleDict(@Pref_RussianLetters(), #WF_RussianLetters)
ConfigsChanged = #True
PushListPosition(Pref_RussianLetters())
ClearGadgetItems(#RussianLetters_ListIcon)
ForEach Pref_RussianLetters()
AddGadgetItem(#RussianLetters_ListIcon, -1, Pref_RussianLetters()\Source+Chr(10)+Pref_RussianLetters()\Replace)
Next
PopListPosition(Pref_RussianLetters())
SetGadgetState(#RussianLetters_ListIcon, ListIndex(Pref_RussianLetters()))
EndIf
Case #EnglishPronunciation_ListIcon
If EditSimpleDict(@Pref_EnglishPronunciation(), #WF_EnglishPronunciation)
ConfigsChanged = #True
PushListPosition(Pref_EnglishPronunciation())
ClearGadgetItems(#EnglishPronunciation_ListIcon)
ForEach Pref_EnglishPronunciation()
AddGadgetItem(#EnglishPronunciation_ListIcon, -1, Pref_EnglishPronunciation()\Source+Chr(10)+Pref_EnglishPronunciation()\Replace)
Next
PopListPosition(Pref_EnglishPronunciation())
SetGadgetState(#EnglishPronunciation_ListIcon, ListIndex(Pref_EnglishPronunciation()))
EndIf
Case #SpecSymbols_ListIcon
If EditSymbolDict(@Pref_SpecSymbols())
ConfigsChanged = #True
PushListPosition(Pref_SpecSymbols())
ClearGadgetItems(#SpecSymbols_ListIcon)
ForEach Pref_SpecSymbols()
State$ = ""
Select Pref_SpecSymbols()\SymbolMode
Case 0
State$ = "При посимвольном чтении"
Case 1
State$ = "Всегда"
EndSelect
AddGadgetItem(#SpecSymbols_ListIcon, -1, Pref_SpecSymbols()\Source+Chr(10)+Pref_SpecSymbols()\Replace+Chr(10)+State$)
Next
PopListPosition(Pref_SpecSymbols())
SetGadgetState(#SpecSymbols_ListIcon, ListIndex(Pref_SpecSymbols()))
EndIf
Case #UserDict_ListIcon
If EditSimpleDict(@Pref_UserDict(), #WF_UserDict)
ConfigsChanged = #True
PushListPosition(Pref_UserDict())
ClearGadgetItems(#UserDict_ListIcon)
ForEach Pref_UserDict()
AddGadgetItem(#UserDict_ListIcon, -1, Pref_UserDict()\Source+Chr(10)+Pref_UserDict()\Replace)
Next
PopListPosition(Pref_UserDict())
SetGadgetState(#UserDict_ListIcon, ListIndex(Pref_UserDict()))
EndIf
EndSelect
EndIf
Case #DeleteEntry_Btn
ActiveGadget.i
Select GetGadgetState(TabsAtBottom)
Case #WF_EnglishLetters
ActiveGadget = #EnglishLetters_ListIcon
Case #WF_EnglishPronunciation
ActiveGadget = #EnglishPronunciation_ListIcon
Case #WF_RussianLetters
ActiveGadget = #RussianLetters_ListIcon
Case #WF_SpecSymbols
ActiveGadget = #SpecSymbols_ListIcon
Case #WF_UserDict
ActiveGadget = #UserDict_ListIcon
Default
ActiveGadget = #Null
EndSelect
If GetGadgetState(ActiveGadget) >= 0
Select ActiveGadget
Case #EnglishLetters_ListIcon
NewMap vars.s()
vars("%entry%") = Pref_EnglishLetters()\Source
If MessageRequester(trl("Удалить произношение "), trlex(~"Вы действительно желаете удалить произношение \"%entry%\"?", vars()), #PB_MessageRequester_YesNo|#MB_ICONQUESTION) = #PB_MessageRequester_Yes
DeleteElement(Pref_EnglishLetters())
ConfigsChanged = #True
PushListPosition(Pref_EnglishLetters())
ClearGadgetItems(#EnglishLetters_ListIcon)
ForEach Pref_EnglishLetters()
AddGadgetItem(#EnglishLetters_ListIcon, -1, Pref_EnglishLetters()\Source+Chr(10)+Pref_EnglishLetters()\Replace)
Next
PopListPosition(Pref_EnglishLetters())
SetGadgetState(#EnglishLetters_ListIcon, ListIndex(Pref_EnglishLetters()))
EndIf
FreeMap(vars())
Case #RussianLetters_ListIcon
NewMap vars.s()
vars("%entry%") = Pref_RussianLetters()\Source
If MessageRequester(trl("Удалить произношение "), trlex(~"Вы действительно желаете удалить произношение \"%entry%\"?", vars()), #PB_MessageRequester_YesNo|#MB_ICONQUESTION) = #PB_MessageRequester_Yes
DeleteElement(Pref_RussianLetters())
ConfigsChanged = #True
PushListPosition(Pref_RussianLetters())
ClearGadgetItems(#RussianLetters_ListIcon)
ForEach Pref_RussianLetters()
AddGadgetItem(#RussianLetters_ListIcon, -1, Pref_RussianLetters()\Source+Chr(10)+Pref_RussianLetters()\Replace)
Next
PopListPosition(Pref_RussianLetters())
SetGadgetState(#RussianLetters_ListIcon, ListIndex(Pref_RussianLetters()))
EndIf
FreeMap(vars())
Case #EnglishPronunciation_ListIcon
NewMap vars.s()
vars("%entry%") = Pref_EnglishPronunciation()\Source
If MessageRequester(trl("Удалить произношение "), trlex(~"Вы действительно желаете удалить произношение \"%entry%\"?", vars()), #PB_MessageRequester_YesNo|#MB_ICONQUESTION) = #PB_MessageRequester_Yes
DeleteElement(Pref_EnglishPronunciation())
ConfigsChanged = #True
PushListPosition(Pref_EnglishPronunciation())
ClearGadgetItems(#EnglishPronunciation_ListIcon)
ForEach Pref_EnglishPronunciation()
AddGadgetItem(#EnglishPronunciation_ListIcon, -1, Pref_EnglishPronunciation()\Source+Chr(10)+Pref_EnglishPronunciation()\Replace)
Next
PopListPosition(Pref_EnglishPronunciation())
SetGadgetState(#EnglishPronunciation_ListIcon, ListIndex(Pref_EnglishPronunciation()))
EndIf
FreeMap(vars())
Case #SpecSymbols_ListIcon
NewMap vars.s()
vars("%entry%") = Pref_SpecSymbols()\Source
If MessageRequester(trl("Удалить произношение "), trlex(~"Вы действительно желаете удалить произношение \"%entry%\"?", vars()), #PB_MessageRequester_YesNo|#MB_ICONQUESTION) = #PB_MessageRequester_Yes
DeleteElement(Pref_SpecSymbols())
ConfigsChanged = #True
ClearGadgetItems(#SpecSymbols_ListIcon)
ForEach Pref_SpecSymbols()
State$ = ""
Select Pref_SpecSymbols()\SymbolMode
Case 0
State$ = "При посимвольном чтении"
Case 1
State$ = "Всегда"
EndSelect
AddGadgetItem(#SpecSymbols_ListIcon, -1, Pref_SpecSymbols()\Source+Chr(10)+Pref_SpecSymbols()\Replace+Chr(10)+State$)
Next
PopListPosition(Pref_SpecSymbols())
SetGadgetState(#SpecSymbols_ListIcon, ListIndex(Pref_SpecSymbols()))
EndIf
FreeMap(vars())
Case #UserDict_ListIcon
NewMap vars.s()
vars("%entry%") = Pref_UserDict()\Source
If MessageRequester(trl("Удалить произношение "), trlex(~"Вы действительно желаете удалить произношение \"%entry%\"?", vars()), #PB_MessageRequester_YesNo|#MB_ICONQUESTION) = #PB_MessageRequester_Yes
DeleteElement(Pref_UserDict())
ConfigsChanged = #True
PushListPosition(Pref_UserDict())
ClearGadgetItems(#UserDict_ListIcon)
ForEach Pref_UserDict()
AddGadgetItem(#UserDict_ListIcon, -1, Pref_UserDict()\Source+Chr(10)+Pref_UserDict()\Replace)
Next
PopListPosition(Pref_UserDict())
SetGadgetState(#UserDict_ListIcon, ListIndex(Pref_UserDict()))
EndIf
FreeMap(vars())
EndSelect
EndIf
Case #Apply_Btn
If SaveConfig() : ConfigsChanged = #False : EndIf
Case #Docs_Btn
If FileSize(GetPathPart(ProgramFilename())+"docs\Russian.html") > 0
RunProgram(GetPathPart(ProgramFilename())+"docs\Russian.html")
Else
MessageRequester(trl("Ошибка"), trl("Не нахожу документации по ожидаемому пути."), #PB_MessageRequester_Error)
EndIf
EndSelect
ElseIf Event = #PB_Event_Menu
Select EventMenu()
Case #MI_Add
Select GetActiveGadget()
Case #EnglishLetters_ListIcon
If AddSimpleDict(#WF_EnglishLetters)
ConfigsChanged = #True
ClearGadgetItems(#EnglishLetters_ListIcon)
ForEach Pref_EnglishLetters()
AddGadgetItem(#EnglishLetters_ListIcon, -1, Pref_EnglishLetters()\Source+Chr(10)+Pref_EnglishLetters()\Replace)
Next
SetGadgetState(#EnglishLetters_ListIcon, ListIndex(Pref_EnglishLetters()))
EndIf
Case #RussianLetters_ListIcon
If AddSimpleDict(#WF_RussianLetters)
ConfigsChanged = #True
ClearGadgetItems(#RussianLetters_ListIcon)
ForEach Pref_RussianLetters()
AddGadgetItem(#RussianLetters_ListIcon, -1, Pref_RussianLetters()\Source+Chr(10)+Pref_RussianLetters()\Replace)
Next
SetGadgetState(#RussianLetters_ListIcon, ListIndex(Pref_RussianLetters()))
EndIf
Case #EnglishPronunciation_ListIcon
If AddSimpleDict(#WF_EnglishPronunciation)
ConfigsChanged = #True
ClearGadgetItems(#EnglishPronunciation_ListIcon)
ForEach Pref_EnglishPronunciation()
AddGadgetItem(#EnglishPronunciation_ListIcon, -1, Pref_EnglishPronunciation()\Source+Chr(10)+Pref_EnglishPronunciation()\Replace)
Next
SetGadgetState(#EnglishPronunciation_ListIcon, ListIndex(Pref_EnglishPronunciation()))
EndIf
Case #SpecSymbols_ListIcon
If AddSymbolDict()
ConfigsChanged = #True
ClearGadgetItems(#SpecSymbols_ListIcon)
ForEach Pref_SpecSymbols()
State$ = ""
Select Pref_SpecSymbols()\SymbolMode
Case 0
State$ = "При посимвольном чтении"
Case 1
State$ = "Всегда"
EndSelect
AddGadgetItem(#SpecSymbols_ListIcon, -1, Pref_SpecSymbols()\Source+Chr(10)+Pref_SpecSymbols()\Replace+Chr(10)+State$)
Next
SetGadgetState(#SpecSymbols_ListIcon, ListIndex(Pref_SpecSymbols()))
EndIf
Case #UserDict_ListIcon
If AddSimpleDict(#WF_UserDict)
ConfigsChanged = #True
ClearGadgetItems(#UserDict_ListIcon)
ForEach Pref_UserDict()
AddGadgetItem(#UserDict_ListIcon, -1, Pref_UserDict()\Source+Chr(10)+Pref_UserDict()\Replace)
Next
SetGadgetState(#UserDict_ListIcon, ListIndex(Pref_UserDict()))
EndIf
EndSelect
Case #MI_Edit
If GetGadgetState(GetActiveGadget()) >= 0
Select GetActiveGadget()
Case #EnglishLetters_ListIcon
If EditSimpleDict(@Pref_EnglishLetters(), #WF_EnglishLetters)
ConfigsChanged = #True
PushListPosition(Pref_EnglishLetters())
ClearGadgetItems(#EnglishLetters_ListIcon)
ForEach Pref_EnglishLetters()
AddGadgetItem(#EnglishLetters_ListIcon, -1, Pref_EnglishLetters()\Source+Chr(10)+Pref_EnglishLetters()\Replace)
Next
PopListPosition(Pref_EnglishLetters())
SetGadgetState(#EnglishLetters_ListIcon, ListIndex(Pref_EnglishLetters()))
EndIf
Case #RussianLetters_ListIcon
If EditSimpleDict(@Pref_RussianLetters(), #WF_RussianLetters)
ConfigsChanged = #True
PushListPosition(Pref_RussianLetters())
ClearGadgetItems(#RussianLetters_ListIcon)
ForEach Pref_RussianLetters()
AddGadgetItem(#RussianLetters_ListIcon, -1, Pref_RussianLetters()\Source+Chr(10)+Pref_RussianLetters()\Replace)
Next
PopListPosition(Pref_RussianLetters())
SetGadgetState(#RussianLetters_ListIcon, ListIndex(Pref_RussianLetters()))
EndIf
Case #EnglishPronunciation_ListIcon
If EditSimpleDict(@Pref_EnglishPronunciation(), #WF_EnglishPronunciation)
ConfigsChanged = #True
PushListPosition(Pref_EnglishPronunciation())
ClearGadgetItems(#EnglishPronunciation_ListIcon)
ForEach Pref_EnglishPronunciation()
AddGadgetItem(#EnglishPronunciation_ListIcon, -1, Pref_EnglishPronunciation()\Source+Chr(10)+Pref_EnglishPronunciation()\Replace)
Next
PopListPosition(Pref_EnglishPronunciation())
SetGadgetState(#EnglishPronunciation_ListIcon, ListIndex(Pref_EnglishPronunciation()))
EndIf
Case #SpecSymbols_ListIcon
If EditSymbolDict(@Pref_SpecSymbols())
ConfigsChanged = #True
PushListPosition(Pref_SpecSymbols())
ClearGadgetItems(#SpecSymbols_ListIcon)
ForEach Pref_SpecSymbols()
State$ = ""
Select Pref_SpecSymbols()\SymbolMode
Case 0
State$ = "При посимвольном чтении"
Case 1
State$ = "Всегда"
EndSelect
AddGadgetItem(#SpecSymbols_ListIcon, -1, Pref_SpecSymbols()\Source+Chr(10)+Pref_SpecSymbols()\Replace+Chr(10)+State$)
Next
PopListPosition(Pref_SpecSymbols())
SetGadgetState(#SpecSymbols_ListIcon, ListIndex(Pref_SpecSymbols()))
EndIf
Case #UserDict_ListIcon
If EditSimpleDict(@Pref_UserDict(), #WF_UserDict)
ConfigsChanged = #True
PushListPosition(Pref_UserDict())
ClearGadgetItems(#UserDict_ListIcon)
ForEach Pref_UserDict()
AddGadgetItem(#UserDict_ListIcon, -1, Pref_UserDict()\Source+Chr(10)+Pref_UserDict()\Replace)
Next
PopListPosition(Pref_UserDict())
SetGadgetState(#UserDict_ListIcon, ListIndex(Pref_UserDict()))
EndIf
EndSelect
EndIf
Case #MI_Delete
If GetGadgetState(GetActiveGadget()) >= 0
Select GetActiveGadget()
Case #EnglishLetters_ListIcon
NewMap vars.s()
vars("%entry%") = Pref_EnglishLetters()\Source
If MessageRequester(trl("Удалить произношение "), trlex(~"Вы действительно желаете удалить произношение \"%entry%\"?", vars()), #PB_MessageRequester_YesNo|#MB_ICONQUESTION) = #PB_MessageRequester_Yes
DeleteElement(Pref_EnglishLetters())
ConfigsChanged = #True
PushListPosition(Pref_EnglishLetters())
ClearGadgetItems(#EnglishLetters_ListIcon)
ForEach Pref_EnglishLetters()
AddGadgetItem(#EnglishLetters_ListIcon, -1, Pref_EnglishLetters()\Source+Chr(10)+Pref_EnglishLetters()\Replace)
Next
PopListPosition(Pref_EnglishLetters())
SetGadgetState(#EnglishLetters_ListIcon, ListIndex(Pref_EnglishLetters()))
EndIf
FreeMap(vars())
Case #RussianLetters_ListIcon
NewMap vars.s()
vars("%entry%") = Pref_RussianLetters()\Source
If MessageRequester(trl("Удалить произношение "), trlex(~"Вы действительно желаете удалить произношение \"%entry%\"?", vars()), #PB_MessageRequester_YesNo|#MB_ICONQUESTION) = #PB_MessageRequester_Yes
DeleteElement(Pref_RussianLetters())
ConfigsChanged = #True
PushListPosition(Pref_RussianLetters())
ClearGadgetItems(#RussianLetters_ListIcon)
ForEach Pref_RussianLetters()
AddGadgetItem(#RussianLetters_ListIcon, -1, Pref_RussianLetters()\Source+Chr(10)+Pref_RussianLetters()\Replace)
Next
PopListPosition(Pref_RussianLetters())
SetGadgetState(#RussianLetters_ListIcon, ListIndex(Pref_RussianLetters()))
EndIf
FreeMap(vars())
Case #EnglishPronunciation_ListIcon
NewMap vars.s()
vars("%entry%") = Pref_EnglishPronunciation()\Source
If MessageRequester(trl("Удалить произношение "), trlex(~"Вы действительно желаете удалить произношение \"%entry%\"?", vars()), #PB_MessageRequester_YesNo|#MB_ICONQUESTION) = #PB_MessageRequester_Yes
DeleteElement(Pref_EnglishPronunciation())
ConfigsChanged = #True
PushListPosition(Pref_EnglishPronunciation())
ClearGadgetItems(#EnglishPronunciation_ListIcon)
ForEach Pref_EnglishPronunciation()
AddGadgetItem(#EnglishPronunciation_ListIcon, -1, Pref_EnglishPronunciation()\Source+Chr(10)+Pref_EnglishPronunciation()\Replace)
Next
PopListPosition(Pref_EnglishPronunciation())
SetGadgetState(#EnglishPronunciation_ListIcon, ListIndex(Pref_EnglishPronunciation()))
EndIf
FreeMap(vars())
Case #SpecSymbols_ListIcon
NewMap vars.s()
vars("%entry%") = Pref_SpecSymbols()\Source
If MessageRequester(trl("Удалить произношение "), trlex(~"Вы действительно желаете удалить произношение \"%entry%\"?", vars()), #PB_MessageRequester_YesNo|#MB_ICONQUESTION) = #PB_MessageRequester_Yes
DeleteElement(Pref_SpecSymbols())
ConfigsChanged = #True
ClearGadgetItems(#SpecSymbols_ListIcon)
ForEach Pref_SpecSymbols()
State$ = ""
Select Pref_SpecSymbols()\SymbolMode
Case 0
State$ = "При посимвольном чтении"
Case 1
State$ = "Всегда"
EndSelect
AddGadgetItem(#SpecSymbols_ListIcon, -1, Pref_SpecSymbols()\Source+Chr(10)+Pref_SpecSymbols()\Replace+Chr(10)+State$)
Next
PopListPosition(Pref_SpecSymbols())
SetGadgetState(#SpecSymbols_ListIcon, ListIndex(Pref_SpecSymbols()))
EndIf
FreeMap(vars())
Case #UserDict_ListIcon
NewMap vars.s()
vars("%entry%") = Pref_UserDict()\Source
If MessageRequester(trl("Удалить произношение "), trlex(~"Вы действительно желаете удалить произношение \"%entry%\"?", vars()), #PB_MessageRequester_YesNo|#MB_ICONQUESTION) = #PB_MessageRequester_Yes
DeleteElement(Pref_UserDict())
ConfigsChanged = #True
PushListPosition(Pref_UserDict())
ClearGadgetItems(#UserDict_ListIcon)
ForEach Pref_UserDict()
AddGadgetItem(#UserDict_ListIcon, -1, Pref_UserDict()\Source+Chr(10)+Pref_UserDict()\Replace)
Next
PopListPosition(Pref_UserDict())
SetGadgetState(#UserDict_ListIcon, ListIndex(Pref_UserDict()))
EndIf
FreeMap(vars())
EndSelect
EndIf
Case #PMI_ApplyConfigs
PostEvent(#PB_Event_Gadget, #MainWindow, #Apply_Btn)
Case #PMI_AddDictEntry
PostEvent(#PB_Event_Menu, #MainWindow, #MI_Add)
Case #PMI_Docs
PostEvent(#PB_Event_Gadget, #MainWindow, #Docs_Btn)
EndSelect
ElseIf Event = #WM_KEYDOWN
Select EventwParam()
Case #VK_APPS
Select GetActiveGadget()
Case #EnglishLetters_ListIcon, #RussianLetters_ListIcon, #EnglishPronunciation_ListIcon, #SpecSymbols_ListIcon, #UserDict_ListIcon
PostEvent(#PB_Event_Gadget, #MainWindow, GetActiveGadget(), #PB_EventType_RightClick)
EndSelect
Case #VK_RETURN
Select GetActiveGadget()
Case #EnglishLetters_ListIcon, #RussianLetters_ListIcon, #EnglishPronunciation_ListIcon, #SpecSymbols_ListIcon, #UserDict_ListIcon
If GetGadgetState(GetActiveGadget()) >= 0
PostEvent(#PB_Event_Menu, #MainWindow, #MI_Edit)
Else
PostEvent(#PB_Event_Menu, #MainWindow, #MI_Add)
EndIf
EndSelect
Case #VK_DELETE
Select GetActiveGadget()
Case #EnglishLetters_ListIcon, #RussianLetters_ListIcon, #EnglishPronunciation_ListIcon, #SpecSymbols_ListIcon, #UserDict_ListIcon
PostEvent(#PB_Event_Menu, #MainWindow, #MI_Delete)
EndSelect
EndSelect
ElseIf Event = #PB_Event_CloseWindow
If ConfigsChanged
Select MessageRequester(trl("Внимание"), trl("Вы внесли изменения в конфигурацию, однако не применили ее. Если просто так покинуть приложение конфигурации, вы потеряете все сделанные изменения. Применить конфигурацию, прежде чем закрыть конфигуратор?"), #PB_MessageRequester_YesNoCancel|#MB_ICONQUESTION)
Case #PB_MessageRequester_Yes
SaveConfig()
Case #PB_MessageRequester_Cancel
Continue
EndSelect
EndIf
Break
EndIf
ForEver
CloseInstance(AppInstance)
Else
MessageRequester(trl("Ошибка"), trl("Другая копия программы уже работает."), #PB_MessageRequester_Error)
EndIf
End
; IDE Options = PureBasic 6.40 (Windows - x64)
; Folding = --
; EnableXP
; DPIAware
; Executable = configurer.exe