EnableExplicit

#alpha_latin = 1
#alpha_Cyrillic = 2

Structure REPLACE_STRUCT
  key.s
  value.s
  lenKey.i
  lenValue.i
EndStructure
  
  
Procedure.i CharIsAlpha(symbol.c)
  ; проверяет, является ли символ алфавитным.
  ; поддерживается основная латиница, кириллица и дополнительные кириллические символы
  ; в случае успеха возвращает следующие значения:
  ; #alpha_latin ; латиница
; #alpha_Cyrillic - кирилица.

  Protected result.i = 0
  Select symbol
    Case 'A' To 'Z', ; латинские заглавные
         'a' To 'z' ; латинские строчные
      result = #alpha_latin   
      Case $0400 To $052F ; кириллица и Дополнительные символы
        result = #alpha_Cyrillic
                EndSelect
              ProcedureReturn result  
              EndProcedure

Procedure.i CharIsAlNum(symbol.c)
  ; проверяет, является ли символ алфавитным или числом.
  ; поддерживается основная латиница, кириллица и дополнительные кириллические символы
  Select symbol
    Case '0' To '9', ; цифры от 0 до 9  
    'A' To 'Z', ; латинские заглавные
 'a' To 'z', ; латинские строчные
$0400 To $052F ; кириллица и Дополнительные символы
    ProcedureReturn #True
        EndSelect
EndProcedure


DataSection
        consonants:
        Data.s "BCDFGHJKLMNPQRSTVWXZbcdfghjklmnpqrstvwxzБВГДЖЗЙКЛМНПРСТФХЦЧШЩЪЬбвгджзйклмнпрстфхцчшщъьҐґ"
        Data.c 0
    EndDataSection    
  Procedure.i  CharIsconsonant(symbol.c)
    ; проверяет, является ли символ согласной буквой.
    ; поддерживается английский и русский алфавит.
    Protected *consonantSymbol.Character = ?consonants
        While *consonantSymbol\c
        If symbol = *consonantSymbol\c
    ProcedureReturn #True
          EndIf
          *consonantSymbol + SizeOf(Character)
          Wend
  EndProcedure
  
  DataSection
    abbrev:
    Data.s "bBcCdDfFgGhHjJkKlLmMnNpPqQrRsStTvVwWxXzZбБвВгГдДжЖзЗкКлЛмМнНпПрРсСтТфФхХцЦчЧшШщЩ"
  Data.C 0  
  EndDataSection
    Procedure.i  CharIsAbbrev(symbol.c)
    ; проверяет, является ли символ входящий в список символов для аббревиатур.
    ; поддерживается английский и русский алфавит.
    Protected *abbrevSymbol.Character = ?abbrev
        While *abbrevSymbol\c
        If symbol = *abbrevSymbol\c
    ProcedureReturn #True
          EndIf
          *abbrevSymbol+ SizeOf(Character)
          Wend
  EndProcedure
    
Procedure.i CharIsDigit(symbol.c)
  ; проверяет, является ли символ десятичным числом.
  If symbol >= '0' And symbol <= '9'
    ProcedureReturn #True
    EndIf
EndProcedure

Procedure CharIsLowerCase(symbol.c)
  ; проверяет, является ли символ строчной буквой.  
  ; поддерживается английский и русский алфавит.
  Select symbol  
  Case 'a' To 'z', ; латинские строчные  
       'а' To 'я','ё' ; русские строчные
    ProcedureReturn #True
    EndSelect
  EndProcedure

Procedure CharIsUpperCase(symbol.c)
  ; проверяет, является ли символ заглавной буквой.  
  ; поддерживается английский и русский алфавит.
  Select symbol  
  Case 'A' To 'Z', ; латинские заглавные  
       'А' To 'Я','Ё' ; русские заглавные
    ProcedureReturn #True
    EndSelect
  EndProcedure
  
  
  DataSection
        vowels:
        Data.s "AEIOUYaeiouyАЕЁИОУЫЭЮЯаеёиоуыэюяЇєіїЄІ"
        Data.c 0
    EndDataSection  
    Procedure.i  CharIsVowel(symbol.c)
    ; проверяет, является ли символ гласной буквой.
    ; поддерживается английский и русский алфавит.
    Protected *vowelSymbol.Character = ?vowels
          While *vowelSymbol\c
        If *vowelSymbol\c = symbol
    ProcedureReturn #True
          EndIf
          *vowelSymbol + SizeOf(Character)
          Wend
                       EndProcedure

  
Procedure.s ReplaceStringSymbols(string.s,ReplaceableSymbols.s,ReplacementSymbol.c= ' ')
 ; Заменяет символы в строке.
 ; параметры:
; string - строка в которой будет производиться замена.
; ReplaceableSymbols - набор символов которые будут заменены в строке, пример: "()*".
  ; ReplacementSymbol - символ на который произойдёт замена набора символов. чаще всего это пробел. этот параметр установлен по умолчанию как пробел.
  ; если написать: Debug ReplaceStringSymbols("hello (world)","()") - результатом будет: "hello  world "
  
  Protected *string.Character = @String  
While *string\c
  Protected *symbols.Character = @ReplaceableSymbols
  While *symbols\c
    If *string\c = *symbols\c
            *string\c = ReplacementSymbol
      Break
      EndIf
      *symbols + SizeOf(Character)  
    Wend  
  *string + SizeOf(Character)  
  Wend  
ProcedureReturn String  
EndProcedure

#LEFT_MARKER = 30
#RIGHT_MARKER = 31
Procedure.i StringFindMarker(string.s,position.i)
  ; функция предназначена для ниженаписанной функции ReplaceStringFromList.
  ; находит первый маркер от текущей позиции к концу строки
  If position > 0
  Protected *symbol.Character = @string
    *symbol + ((position-1) * SizeOf(Character))
        While *symbol\c
    If *symbol\c = #LEFT_MARKER Or *symbol\c = #RIGHT_MARKER
      ProcedureReturn *symbol\c
    EndIf
    *symbol + SizeOf(Character)
Wend
    EndIf  
    EndProcedure
    
    Procedure.s StringRemoveMarkers(string.s)
  ; функция предназначена для ниженаписанной функции ReplaceStringFromList.
  ; убирает маркеры из строки
      Protected *symbol.Character   = @String
      Protected result.s
      While *symbol\c
    If *symbol\c = #LEFT_MARKER Or *symbol\c = #RIGHT_MARKER
      *symbol + SizeOf(Character)
      Continue
    EndIf
    result + Chr(*symbol\c)
        *symbol + SizeOf(Character)
Wend
ProcedureReturn result
    EndProcedure

    
Procedure.s ReplaceStringFromList(string.s, List ReplacementList.REPLACE_STRUCT())
; находит в строке совпадения по списку   ключей подстрок, и производит умную замену на их значения.
  ; параметры:
  ; string - строка в которой будет производиться замена.
  ; ReplacementList() - список типа REPLACE_STRUCT, по которому будет производиться поиск и замена.
            If ListSize(ReplacementList())
    ForEach ReplacementList()
      Protected position.i = 1
      While #True
        position = FindString(string, ReplacementList()\key, position, #PB_String_NoCase)
    If position = 0: Break: EndIf
    Protected Marker.i = StringFindMarker(string,position)
    If Not Marker = #RIGHT_MARKER Or Marker = 0       
    String = Mid(string, 1, position - 1) + Chr(#LEFT_MARKER) + ReplacementList()\value + Chr(#RIGHT_MARKER) + Mid(string, position + ReplacementList()\lenKey)
  EndIf  
position + ReplacementList()\lenValue  
Wend
Next
EndIf
ProcedureReturn StringRemoveMarkers(String)
EndProcedure
  
Prototype.i iterfunction(text.c)
  Procedure StringIterator(text.s,function.iterfunction)
    ; функция перебирает символы в строке.
    ; эта функция сделана для экономии кода, чтобы В ниженаписанных  функциях не повторять одно и тоже.
    ; параметры:
    ; text - строка в которой будет перебор
    ; function - функция которая будет вызываться при каждой итерации, к примеру:CharIsDigit()
    
    Protected *char.Character = @text
        While *char\c    
      Protected result = function(*char\c)
    If result = #False
    ProcedureReturn #False  
    EndIf  
*char+SizeOf(Character)  
Wend
ProcedureReturn result
EndProcedure
 
      Procedure StringIsAlpha(text.s)
; проверяет, вся ли строка состоит из алфавитных букв.
        ; в случае успеха возвращает не нуль.
        ProcedureReturn StringITERATOR(text,@CharIsAlpha())
EndProcedure

Procedure StringIsConsonant(text.s)
; проверяет вся ли строка состоит из согласных букв.  
ProcedureReturn StringIterator(text,@CharIsconsonant())  
EndProcedure

Procedure StringIsAbbrev(text.s)
; проверяет вся ли строка состоит из символов, являющихся аббревиатурными.
ProcedureReturn StringIterator(text,@CharIsAbbrev())  
EndProcedure


      Procedure StringIsDigit(text.s)
; проверяет, вся ли строка состоит из десятичных цифр.
    ProcedureReturn StringITERATOR(text,@CharIsDigit())
EndProcedure

Procedure StringIsLowerCase(text.s)
; проверяет, вся ли строка состоит из строчных букв.
     ProcedureReturn StringITERATOR(text,@CharIsLowerCase())
     EndProcedure
 
  Procedure StringIsUpperCase(text.s)
; проверяет, вся ли строка состоит из заглавных букв.
  ProcedureReturn StringITERATOR(text,@CharIsUpperCase())  
  EndProcedure
  
  Procedure StringIsVowel(text.s)
    ; проверяет, вся ли строка состоит из гласных букв.
    ProcedureReturn StringIterator(text,@CharIsVowel())
  EndProcedure
  
    Procedure.s StringCaseByNum(Text.s, Num.i)
  ;  Спасибо Outsider!
  
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

  If FindString(Text, "[") And FindString(Text, "]")
While FindString(Text, "[") Or  FindString(Text, "]")
Protected Leftbr.i = FindString(Text, "[")
Protected Rightbr.i = FindString(Text, "]")
Protected Pattern.S = Mid(Text, Leftbr+1, Rightbr-Leftbr-1)
Protected ReservedString.s = Mid(Text, Rightbr+1)
Text = Left(Text, Leftbr-1)
If Val(Right(Str(Num), 2)) >= 11 And Val(Right(Str(Num), 2)) <= 14
Text + StringField(Pattern, 1, "|")
Else
Select Val(Right(Str(Num), 1))
Case 1
    Text + StringField(Pattern, 2, "|")
Case 2 To 4
Text + StringField(Pattern, 3, "|")
Default
Text + StringField(Pattern, 1, "|")
EndSelect
EndIf
Text + Right(ReservedString, Len(ReservedString))
Wend
EndIf
If FindString(Text, "%d")
Text = ReplaceString(Text, "%d", Str(Num))
EndIf
ProcedureReturn Text
EndProcedure


Procedure.i cp1251(string.s)
  ; функция конвертирует из utf-16 в cp-1251.
  Protected *symbol.Character = @String
  Protected *result = AllocateMemory(Len(String)+1)
  If *result
    Protected *ansi.Ascii = *result
    While *symbol\c
      Select *symbol\c
          Case 'А' To 'я'
*ansi\a = *symbol\c - 848            
          Case 'Ё'
          *ansi\a = 168
          Case 'ё'
     *ansi\a = 184       
   Case '…'  
   *ansi\a = '.' 
   Default
     *ansi\a = *symbol\c
 EndSelect
          *ansi + 1
        *symbol + SizeOf(Character)  
      Wend  
    ProcedureReturn *result
    EndIf
          EndProcedure
          
          Procedure.i cp1251ptr(*string)
  ; функция конвертирует из utf-16 в cp-1251.
  Protected *symbol.Character = *String
  Protected *result = AllocateMemory(MemoryStringLength(*String)+1)
  If *result
    Protected *ansi.Ascii = *result
    While *symbol\c
      Select *symbol\c
          Case 'А' To 'я'
*ansi\a = *symbol\c - 848            
          Case 'Ё'
          *ansi\a = 168
          Case 'ё'
     *ansi\a = 184       
   Case '…'  
   *ansi\a = '.' 
   Default
     *ansi\a = *symbol\c
 EndSelect
          *ansi + 1
        *symbol + SizeOf(Character)  
      Wend  
    ProcedureReturn *result
    EndIf
          EndProcedure

          
          
          #TRIM_SPACES = 1
          #TRIM_ZEROS = 2
          #REVERSE_NUMBER = 4
          Procedure.s triadNumber(number.s,flags.i = #TRIM_SPACES)
            ; разбивает число на триады.
            ; параметры:
            ; number - строка с числом которое надо преобразовать.
            ; flags - опциональный параметр из комбинации из следующих флагов:
            ; #TRIM_ZEROS - убирает ненужные нули вначале числа, пример 032 будет 32 (по умолчанию не установлен),
            ; #TRIM_SPACES - убирает пробелы по краям числа (по умолчанию установлен)),
            ; #REVERSE_NUMBER - разворачивает число на оборот (по умолчанию не установлен).
            ; возвращает строку с числом разделённым пробелами.
            ; пример: 123456789, вернёт как: 123 456 789
            Protected triad.i = 0
                                                Protected tmp.s = ReverseString(number) ; развернём строку. так не быстрее рассматривать число справа, но проще.
                                                                                                Protected *symbol.Character = @TMP
                                                                                                Protected result.s
                                                                                                While CharIsDigit(*symbol\c)
                        ; бъём число по 3 разряда  
                          If triad % 3 = 0
                            result + " "
                          EndIf
                                                    result + Chr(*symbol\c)
                                                    triad + 1
                                                    *symbol + SizeOf(Character)
                          Wend  
                                                    If flags <= 0 Or flags > #TRIM_ZEROS
                            flags | #TRIM_SPACES
                            EndIf
                            If Not flags & #REVERSE_NUMBER
                            result = ReverseString(result)
                            EndIf
                            If flags & #TRIM_SPACES
                            result = Trim(result)
                            EndIf
                            If flags & #TRIM_ZEROS
                            result = LTrim(result,"0")
                            EndIf
                          ProcedureReturn result
                        EndProcedure
                        
                        
; Структура NTW_MASK
; Позволяет задать значения цифр, десятков, сотен и других разрядов чисел для конвертации.
; Может заполняться соответственно формируемому языку.
; Также, могут быть сформированы разные падежи для склонения.
; Сорри, но другого гибкого варианта я не смог придумать
Structure NTW_MASK
; Массив с названиями цифр от нуля до девятнадцати.
Digits.s[20]
; Массив с названиями цифр от нуля до девятнадцати в женском роде. Например 1=одна, 2=две и так далее. Можно не заполнять весь. При отсутствии варианта отсюда, он будет взят из Digits[].
Digits1.s[20]
; Массив с названиями десятков. Заполнять соответственно цифре десятка. т.е. элемент 2 в массиве должен быть заполнен как "двадцать".
Dozens.s[10]
; Массив с названиями сотен. Заполнять соответственно цифре сотни. т.е. элемент 2 в массиве должен быть заполнен как "двести".
Hundreds.s[10]
; Маска названия тысяч. Может содержать дополнительное склонение по StringCaseByNum, т.е., "тысяч[|а|и]"
Thousands.s
; Маска названия миллионов. Может содержать дополнительное склонение по StringCaseByNum, т.е., "миллион[ов||а]"
Millions.s
; Маска названия миллиардов. Может содержать дополнительное склонение по StringCaseByNum, т.е., "миллиард[ов||а]"
Billions.s
; Финальный предлог, если есть. Полезно при создании фразы в языках, где это используется. Например, в английском: Two hundred and thirty five", где "And" - это финальный предлог.
sAnd.s
EndStructure


; Процедура ConvertNumbersToWords
; Конвертирует числа, встреченные в строке, в словесное обозначение.
; Параметры: 
; Text.s: Строка, в которой нужно произвести конвертацию
; *Mask.NTW_MASK: Заполненная структура NTW_MASK для конвертации. Описания полей см. в структуре над каждым из них.
; Возвращает строку с преобразованными числами в словесное обозначение.
; Примеры:
; Debug ConvertNumbersToWord("У Леши 15 яблок.", RussianDigits) >> "У Леши пятнадцать яблок."
; Debug ConvertNumbersToWord("Мы купили этот аппарат за 359 евро.", RussianDigits) >> "Мы купили этот аппарат за триста пятьдесят девять евро."
; Debug ConvertNumbersToWord("I have 125 dollars in my pocket.", EnglishDigits) >> "I have one hundred and twenty five dollars in my pocket."
; Внимание! В код модуля не входят заполненые структуры цифр и обозначений разрядов! Программист сам должен заполнить структуру для используемого языка интерфейса.
Procedure.s ConvertNumbersToWords(Text.s, *Mask.NTW_MASK)
Protected *Chars.Character = @Text
Protected Result.s
Debug "Вход: "+Text
While *Chars\c
Protected *PrevSymbol.Character
Protected *NextSymbol.Character
Debug "Текущий символ: "+Chr(*Chars\c)
Protected Number.s = #Null$
If CharIsDigit(*Chars\c)
Debug "If CharIsDigit(*Chars\c) = истина"
*PrevSymbol = *Chars-SizeOf(Character)
Debug "Предыдущий перед числом символ: "+Chr(*PrevSymbol\c)+"("+*PrevSymbol\c+")"
Debug "Составляем строку числа"
While CharIsDigit(*Chars\c)
Number + Chr(*Chars\c)
Debug "Число: "+Number
*Chars + SizeOf(Character)
Wend
*NextSymbol = *Chars
*Chars - SizeOf(Character)
Debug "Следующий после числа символ: "+Chr(*NextSymbol\c)+"("+*NextSymbol\c+")"
Debug "Вычлененное число: "+Number
If Number <> #Null$
Debug "If Number <> #Null$ истина"
Protected ProcNumber.s
Debug "Начинаем обрабатывать разряды"
If Len(Number) <= 12
Debug "Число "+Len(Number)+"-значное. Такое число мы можем обработать."
Number = ReverseString(Number)
Debug "Развернутое число: "+Number
Protected I.I
For i = 1 To Len(Number)
Protected CurNumber.i = Val(Mid(Number, i, 1))
Debug "Текущая цифра: "+CurNumber
With *Mask
Select i
Case 1
Debug "Обрабатываем последнее число "+CurNumber
If CurNumber > 0
Debug "Цифра больше ноля. Она должна быть записана как "+\Digits[CurNumber]
ProcNumber + ReverseString(\Digits[CurNumber])
EndIf
Case 2
Debug "Обрабатываем десяток "+CurNumber
If CurNumber = 1
Debug "Цифра единица. Это не десяток. Она должна быть обработана с вышестоящей цифрой. Она должна быть записана как "+\Digits[Val(Str(CurNumber)+Mid(Number, i-1, 1))]
ProcNumber = ReverseString(\Digits[Val(Str(CurNumber)+Mid(Number, i-1, 1))]+" ")
ElseIf CurNumber > 1
Debug "Цифра больше единицы. Она должна быть записана как "+\Dozens[CurNumber]
ProcNumber + ReverseString(\Dozens[CurNumber]+" ")
If \sAnd
ProcNumber + ReverseString(\sAnd+" ")
EndIf
EndIf
Case 3
Debug "Обработка сотни" + CurNumber
If CurNumber > 0
Debug "Цифра больше ноля. Она должна быть записано как "+\Hundreds[CurNumber]
ProcNumber + ReverseString(\Hundreds[CurNumber]+" ")
EndIf
Case 4
Debug "Обработка тысячи "+CurNumber
If Val(Mid(Number, i+1, 1)) <> 1
Debug "Заглянули в будущее. Следующая цифра "+Val(Mid(Number, i+1, 1))+" не равна единице. Значит мы должны обработать текущую цифру."
If CurNumber > 0
If \Digits1[CurNumber]
Debug "Цифра больше единицы. Она должна быть записана как "+StringCaseByNum(\Digits1[CurNumber]+" "+\Thousands, CurNumber)
ProcNumber + ReverseString(StringCaseByNum(\Digits1[CurNumber]+" "+\Thousands, CurNumber)+", ")
Else
Debug "Цифра больше единицы. Она должна быть записана как "+StringCaseByNum(\Digits[CurNumber]+" "+\Thousands, CurNumber)
ProcNumber + ReverseString(StringCaseByNum(\Digits[CurNumber]+" "+\Thousands, CurNumber)+", ")
EndIf
EndIf
ElseIf Val(Mid(Number, i+1, 1)) = 1
Debug "Заглянули в будущее. Следующая цифра "+Val(Mid(Number, i+1, 1))+" единица. Значит мы должны просто дописать название разряда"
ProcNumber + ReverseString(StringCaseByNum(\Thousands, 0)+", ")
EndIf
Case 5
Debug "Обработка десятка тысячи "+CurNumber
If CurNumber = 1
Debug "Цифра равна единице. Значит это двузначное число до десятка. Она должна быть записана как "+\Digits[Val(Str(CurNumber)+Mid(Number, i-1, 1))]
ProcNumber + ReverseString(\Digits[Val(Str(CurNumber)+Mid(Number, i-1, 1))]+" ")
ElseIf CurNumber > 1
Debug "Цифра больше единицы. Она должна быть записана как "+\Dozens[CurNumber]
ProcNumber + ReverseString(\Dozens[CurNumber]+" ")
EndIf
Case 6
Debug "Обработка сотни тысячи " + CurNumber
If CurNumber > 0
Debug "Цифра больше ноля. Она должна быть записана как "+\Hundreds[CurNumber]
If ProcNumber
Debug "В ProcNumber уже есть результат. Просто вписываем то, что мы раньше задумали."
ProcNumber + ReverseString(\Hundreds[CurNumber]+" ")
Else
Debug "В ProcNumber ничего нет. Нам тогда нужно дописать разряд тысяч"
ProcNumber + ReverseString(\Hundreds[CurNumber]+" "+StringCaseByNum(\Thousands, 0)+" ")
EndIf
EndIf
Case 7
Debug "Обработка миллиона "+CurNumber
If Val(Mid(Number, i+1, 1)) <> 1
Debug "Заглянули в будущее. Следующая цифра "+Val(Mid(Number, i+1, 1))+" не равна единице. Значит мы должны обработать текущую цифру."
If CurNumber > 0
If \Digits1[CurNumber]
Debug "Цифра больше единицы. Она должна быть записана как "+StringCaseByNum(\Digits1[CurNumber]+" "+\Millions, CurNumber)
ProcNumber + ReverseString(StringCaseByNum(\Digits1[CurNumber]+" "+\Millions, CurNumber)+", ")
Else
Debug "Цифра больше единицы. Она должна быть записана как "+StringCaseByNum(\Digits[CurNumber]+" "+\Millions, CurNumber)
ProcNumber + ReverseString(StringCaseByNum(\Digits[CurNumber]+" "+\Millions, CurNumber)+", ")
EndIf
EndIf
ElseIf Val(Mid(Number, i+1, 1)) = 1
Debug "Заглянули в будущее. Следующая цифра "+Val(Mid(Number, i+1, 1))+" единица. Значит мы должны просто дописать название разряда"
ProcNumber + ReverseString(StringCaseByNum(\Millions, 0)+", ")
EndIf
Case 8
Debug "Обработка десятка миллиона "+CurNumber
If CurNumber = 1
Debug "Цифра равна единице. Значит это двузначное число до десятка. Она должна быть записана как "+\Digits[Val(Str(CurNumber)+Mid(Number, i-1, 1))]
ProcNumber + ReverseString(\Digits[Val(Str(CurNumber)+Mid(Number, i-1, 1))]+" ")
ElseIf CurNumber > 1
Debug "Цифра больше единицы. Она должна быть записана как "+\Dozens[CurNumber]
ProcNumber + ReverseString(\Dozens[CurNumber]+" ")
EndIf
Case 9
Debug "Обработка сотни миллиона " + CurNumber
If CurNumber > 0
Debug "Цифра больше ноля. Она должна быть записана как "+\Hundreds[CurNumber]
If ProcNumber
Debug "В ProcNumber уже есть результат. Просто вписываем то, что мы раньше задумали."
ProcNumber + ReverseString(\Hundreds[CurNumber]+" ")
Else
Debug "В ProcNumber ничего нет. Нам тогда нужно дописать разряд миллиона"
ProcNumber + ReverseString(\Hundreds[CurNumber]+" "+StringCaseByNum(\Millions, 0)+" ")
EndIf
EndIf
Case 10
Debug "Обработка миллиарда "+CurNumber
If Val(Mid(Number, i+1, 1)) <> 1
Debug "Заглянули в будущее. Следующая цифра "+Val(Mid(Number, i+1, 1))+" не равна единице. Значит мы должны обработать текущую цифру."
If CurNumber > 0
If \Digits1[CurNumber]
Debug "Цифра больше единицы. Она должна быть записана как "+StringCaseByNum(\Digits1[CurNumber]+" "+\Billions, CurNumber)
ProcNumber + ReverseString(StringCaseByNum(\Digits1[CurNumber]+" "+\Billions, CurNumber)+", ")
Else
Debug "Цифра больше единицы. Она должна быть записана как "+StringCaseByNum(\Digits[CurNumber]+" "+\Billions, CurNumber)
ProcNumber + ReverseString(StringCaseByNum(\Digits[CurNumber]+" "+\Billions, CurNumber)+", ")
EndIf
EndIf
ElseIf Val(Mid(Number, i+1, 1)) = 1
Debug "Заглянули в будущее. Следующая цифра "+Val(Mid(Number, i+1, 1))+" единица. Значит мы должны просто дописать название разряда"
ProcNumber + ReverseString(StringCaseByNum(\Billions, 0)+", ")
EndIf
Case 11
Debug "Обработка десятка миллиарда "+CurNumber
If CurNumber = 1
Debug "Цифра равна единице. Значит это двузначное число до десятка. Она должна быть записана как "+\Digits[Val(Str(CurNumber)+Mid(Number, i-1, 1))]
ProcNumber + ReverseString(\Digits[Val(Str(CurNumber)+Mid(Number, i-1, 1))]+" ")
ElseIf CurNumber > 1
Debug "Цифра больше единицы. Она должна быть записана как "+\Dozens[CurNumber]
ProcNumber + ReverseString(\Dozens[CurNumber]+" ")
EndIf
Case 12
Debug "Обработка сотни миллиарда " + CurNumber
If CurNumber > 0
Debug "Цифра больше ноля. Она должна быть записана как "+\Hundreds[CurNumber]
If ProcNumber
Debug "В ProcNumber уже есть результат. Просто вписываем то, что мы раньше задумали."
ProcNumber + ReverseString(\Hundreds[CurNumber])
Else
Debug "В ProcNumber ничего нет. Нам тогда нужно дописать разряд миллиарда"
ProcNumber + ReverseString(\Hundreds[CurNumber]+" "+StringCaseByNum(\Billions, 0)+" ")
EndIf
EndIf
EndSelect
EndWith
Debug "Содержание ProcNumber: "+ReverseString(ProcNumber)
Next
Debug "Обработали. Теперь приводим в порядок строку с числом"
ProcNumber = ReverseString(ProcNumber)
If Left(ProcNumber, 1) = " "
Debug "В начале строки есть пробел. Откусываем."
ProcNumber = Mid(ProcNumber, 2)
EndIf
If Right(ProcNumber, 1) = " "
Debug "В конце строки есть пробел. Откусываем."
ProcNumber = Mid(ProcNumber, 1, Len(ProcNumber)-1)
EndIf
Debug "Почищенный ProcNumber выглядит как "+ProcNumber
Else
Debug "Число "+Number+" "+Len(Number)+"-значное. Такое число мы обработать не можем. Просто запишем по цифрам."
For i.i = 1 To Len(Number)
CurNumber.i = Val(Mid(Number, i, 1))
Debug "Текущая цифра: "+CurNumber
With *Mask
If i > 1
ProcNumber + ", " + \Digits[CurNumber]
Else
ProcNumber = \Digits[CurNumber]
EndIf
EndWith
Next
Debug "Обработали. ProcNumber выглядит как "+ProcNumber
EndIf
If *PrevSymbol\c <> ' ' And *PrevSymbol\c <> 0
Debug "Предыдущий перед числом символ не пробел и не нулевой символ. Приклеиваем к Result лишний пробел"
Result + " "
EndIf
Debug "ДОбавляем обработанное число" 
Result + ProcNumber
If *NextSymbol\c <> ' ' And *NextSymbol\c <> 0
Debug "Следующий после числа символ не пробел и не нулевой символ. Приклеиваем к Result лишний пробел"
Result + " "
EndIf
EndIf
Else
Result + Chr(*Chars\c)
EndIf
*Chars + SizeOf(Character)
Wend
ProcedureReturn Result
EndProcedure


; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 3
; FirstLine = 2
; Folding = -----
; EnableXP