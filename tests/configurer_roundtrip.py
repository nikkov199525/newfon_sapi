from pathlib import Path
import os, re, subprocess, configparser, sys
bin=Path(sys.argv[1]).resolve()
folder=bin.parent/'configurer-test'
folder.mkdir(exist_ok=True)
prefs=folder/'prefs.ini'
prefs.write_text(re.sub(r'sample_rate = \d+','sample_rate = 13025',(bin/'prefs.ini').read_text(encoding='utf-8')).replace('interpolation_multiplier = 1','interpolation_multiplier = 4').replace('UseLegacyRateAlgo = True','UseLegacyRateAlgo = False').replace('dec_sep_point = True','dec_sep_point = False').replace('accel = 0','accel = 5').replace('[english_pronunciation]\n','[english_pronunciation]\nѯ = кс\n')+'\n[FutureSettings]\ncustom = сохранить\n',encoding='utf-8')
(folder/'ru_dict.dic').write_text('молоко моло+ко\n',encoding='utf-8-sig')
env=dict(os.environ, NEWFON_CONFIG_DIR=str(folder))
subprocess.run([str(bin/'NewfonConfigurer.exe'),'--test-roundtrip'],env=env,check=True,timeout=15)
c=configparser.ConfigParser(interpolation=None)
c.read(prefs,encoding='utf-8-sig')
assert c['General']['sample_rate']=='13025'
assert c['General']['interpolation_multiplier']=='4'
assert c['General']['uselegacyratealgo']=='False'
assert c['General']['dec_sep_point']=='False'
assert c['General']['dec_sep_comma']=='True'
assert c['General']['accel']=='5'
assert c['FutureSettings']['custom']=='сохранить'
assert c['russian_letters']['ѣ']=='ять'
assert c['english_pronunciation']['j']=='дж'
assert all(k.isascii() for k in c['english_pronunciation'])
assert c['symbols']['ѣ']=='е:1'
assert c['symbols']['ѯ']=='кс:1'
assert 'disable_decimal_separator' not in c['General']
assert not (folder/'newfon.ini').exists()
assert (folder/'ru_dict.dic').read_text(encoding='utf-8-sig').strip()=='молоко моло+ко'
(folder/'ru_dict.dic').write_text('',encoding='utf-8-sig')
subprocess.run([str(bin/'NewfonConfigurer.exe'),'--test-roundtrip'],env=env,check=True,timeout=15)
assert (folder/'ru_dict.dic').read_text(encoding='utf-8-sig')==''
print('PureBasic roundtrip: scalar options, Cyrillic, symbols, unknown settings and empty dictionary OK')
