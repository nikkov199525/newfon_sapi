; Additional core settings, stored in [General] of prefs.ini.
Enumeration 3000
#NF_SampleRate
#NF_Multiplier
#NF_Algorithm
#NF_Acceleration
#NF_Legacy
#NF_DecimalPoint
#NF_DecimalComma
EndEnumeration
Global NF_SampleRate.i = 10000, NF_Multiplier.i = 1, NF_Algorithm.i, NF_Acceleration.i
Global NF_Legacy.i = 1, NF_DecimalPoint.i = 1, NF_DecimalComma.i = 1

Procedure.s NewfonConfigDir()
  Protected Path.s = GetEnvironmentVariable("NEWFON_CONFIG_DIR")
  If Path = ""
    ; Per-user settings in AppData\Roaming (#PB_Directory_ProgramData is that
    ; folder despite its name); the engine reads the same place.
    Path = GetUserDirectory(#PB_Directory_ProgramData)+"NewfonSAPI"
  EndIf
  If Right(Path, 1) <> "\" : Path + "\" : EndIf
  CreateDirectory(Path)
  ProcedureReturn Path
EndProcedure

; The slider runs 0..100 over 10000..11025 Hz, exactly as in the original
; configurer: 0 is the plain phonemophone, 100 is close to My Mouse.
#NF_RateMin = 10000
#NF_RateMax = 11025

Procedure.i NF_RateToSlider(Rate.i)
  If Rate <= #NF_RateMin : ProcedureReturn 0 : EndIf
  If Rate >= #NF_RateMax : ProcedureReturn 100 : EndIf
  ProcedureReturn Round((Rate-#NF_RateMin)*100.0/(#NF_RateMax-#NF_RateMin), #PB_Round_Nearest)
EndProcedure

Procedure.i NF_SliderToRate(Position.i)
  If Position <= 0 : ProcedureReturn #NF_RateMin : EndIf
  If Position >= 100 : ProcedureReturn #NF_RateMax : EndIf
  ProcedureReturn #NF_RateMin + Round(Position*(#NF_RateMax-#NF_RateMin)/100.0, #PB_Round_Nearest)
EndProcedure

Procedure.i NF_ReadBoolean(Key.s, DefaultValue.i = 1)
  Protected Value.s = LCase(ReadPreferenceString(Key, Str(DefaultValue)))
  ProcedureReturn Bool(Value = "true" Or Value = "yes" Or Value = "on" Or Value = "1")
EndProcedure

Procedure EnsurePrefs()
  Protected Path.s = NewfonConfigDir()+"prefs.ini"
  If FileSize(Path) < 0
    If CopyFile(GetPathPart(ProgramFilename())+"prefs.ini", Path) = 0
      MessageRequester("Newfon", "Не найден шаблон prefs.ini рядом с конфигуратором.", #PB_MessageRequester_Error)
      End 1
    EndIf
  EndIf
EndProcedure

Procedure LoadExtraParameters()
  NF_SampleRate = ReadPreferenceInteger("sample_rate", 10000)
  If NF_SampleRate < 8000 Or NF_SampleRate > 16000 : NF_SampleRate = 10000 : EndIf
  NF_Multiplier = ReadPreferenceInteger("interpolation_multiplier", 1)
  If NF_Multiplier = 3 : NF_Multiplier = 4 : EndIf
  If NF_Multiplier < 1 Or NF_Multiplier > 4 : NF_Multiplier = 1 : EndIf
  NF_Algorithm = ReadPreferenceInteger("interpolation_algorithm", 0)
  If NF_Algorithm < 0 Or NF_Algorithm > 1 : NF_Algorithm = 0 : EndIf
  ; Same levels as the NVDA driver: 0 is off, 7 the mildest, 1 the strongest.
  NF_Acceleration = ReadPreferenceInteger("accel", 0)
  If NF_Acceleration < 0 Or NF_Acceleration > 7 : NF_Acceleration = 0 : EndIf
  NF_Legacy = NF_ReadBoolean("UseLegacyRateAlgo")
  NF_DecimalPoint = NF_ReadBoolean("dec_sep_point")
  NF_DecimalComma = NF_ReadBoolean("dec_sep_comma")
EndProcedure

Procedure SaveExtraParameters()
  WritePreferenceInteger("sample_rate", NF_SampleRate)
  WritePreferenceInteger("interpolation_multiplier", NF_Multiplier)
  WritePreferenceInteger("interpolation_algorithm", NF_Algorithm)
  WritePreferenceInteger("accel", NF_Acceleration)
  WritePreferenceString("UseLegacyRateAlgo", StringField("False True", NF_Legacy+1, " "))
  WritePreferenceString("dec_sep_point", StringField("False True", NF_DecimalPoint+1, " "))
  WritePreferenceString("dec_sep_comma", StringField("False True", NF_DecimalComma+1, " "))
EndProcedure

; Every combo box gets its own text label created right before it:
; NVDA names a combo box after the preceding static text.
Procedure NewfonParameterGadgets()
  Protected i.i
  TextGadget(#PB_Any, 10, 105, 170, 20, "Частота дискретизации:")
  TrackBarGadget(#NF_SampleRate, 180, 103, 190, 22, 0, 100)
  SetGadgetState(#NF_SampleRate, NF_RateToSlider(NF_SampleRate))
  GadgetToolTip(#NF_SampleRate, "Скорость синтеза: 0 — стандартный фонемафон (10000 Гц), 100 — приближенный к My Mouse (11025 Гц). Чем выше, тем быстрее и выше голос.")
  TextGadget(#PB_Any, 390, 105, 170, 20, "Множитель интерполяции:")
  ComboBoxGadget(#NF_Multiplier, 560, 103, 60, 22)
  AddGadgetItem(#NF_Multiplier, -1, "1") : AddGadgetItem(#NF_Multiplier, -1, "2") : AddGadgetItem(#NF_Multiplier, -1, "4")
  SetGadgetState(#NF_Multiplier, Bool(NF_Multiplier=2)+2*Bool(NF_Multiplier=4))
  GadgetToolTip(#NF_Multiplier, "Во сколько раз поднять частоту вывода в SAPI: 1 — 11025 Гц, 2 — 22050, 4 — 44100. Звук становится глаже, но программе приходится обрабатывать больше данных.")
  TextGadget(#PB_Any, 630, 105, 165, 20, "Алгоритм интерполяции:")
  ComboBoxGadget(#NF_Algorithm, 795, 103, 150, 22)
  AddGadgetItem(#NF_Algorithm, -1, "Линейная") : AddGadgetItem(#NF_Algorithm, -1, "Нулевого порядка")
  SetGadgetState(#NF_Algorithm, NF_Algorithm)
  TextGadget(#PB_Any, 955, 105, 80, 20, "Ускорение:")
  ComboBoxGadget(#NF_Acceleration, 1035, 103, 80, 22)
  AddGadgetItem(#NF_Acceleration, -1, "Выкл")
  For i = 1 To 7 : AddGadgetItem(#NF_Acceleration, -1, Str(i)) : Next
  SetGadgetState(#NF_Acceleration, NF_Acceleration)
  GadgetToolTip(#NF_Acceleration, "Дополнительно ускоряет всю речь, как в Newfon: 1 — сильнее всего, 7 — слабее всего.")
  CheckBoxGadget(#NF_Legacy, 10, 130, 180, 22, "Исходный алгоритм")
  SetGadgetState(#NF_Legacy, NF_Legacy)
  GadgetToolTip(#NF_Legacy, "Переход между звуками как в Newfon. При снятой галочке используется адаптивный алгоритм ru_tts.")
  ; The checkboxes forbid, so they are set when the setting in prefs.ini is off.
  CheckBoxGadget(#NF_DecimalPoint, 200, 130, 400, 22, "Запретить использовать десятичный разделитель с точкой")
  SetGadgetState(#NF_DecimalPoint, 1-NF_DecimalPoint)
  GadgetToolTip(#NF_DecimalPoint, "По умолчанию 3.14 читается как «три целых четырнадцать сотых». С этой галочкой число читается как есть, что удобно для номеров версий.")
  CheckBoxGadget(#NF_DecimalComma, 610, 130, 410, 22, "Запретить использовать десятичный разделитель с запятой")
  SetGadgetState(#NF_DecimalComma, 1-NF_DecimalComma)
  GadgetToolTip(#NF_DecimalComma, "То же самое для чисел вида 3,14.")
EndProcedure
