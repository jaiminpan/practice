
-- Transfer
-- FROM: '-':8 '0324':9 '100':1 'gm':7 'pcs':2 '字母':5 '数字':4 '积木':6 '精品':3
-- TO: -|0324|100|gm|pcs|字母|数字|积木|精品
CREATE OR REPLACE FUNCTION pg_ts_trans(words tsvector) RETURNS text AS
$$
BEGIN
	return trim(both '''' from regexp_replace(strip(words)::text, ''' ''', '|', 'g'));
END
$$ LANGUAGE plpgsql strict;

-- same as pg_ts_trans but slower
CREATE OR REPLACE FUNCTION pg_ts_trans2(words tsvector) RETURNS text AS
$$
DECLARE
	v1 text := '';
BEGIN
	v1 := regexp_replace(strip(words)::text, '''', '', 'g');
	return regexp_replace(v1, '\s+', '|', 'g');
END
$$ LANGUAGE plpgsql strict;

-- check 身份证合法性
CREATE or replace FUNCTION py_idcard_check(idstr varchar) RETURNS Boolean AS 
$$
    try:
        if len(idstr) != 18:
            return False

        code = '10X98765432'[sum(map(lambda x: int(x[0]) * x[1], zip(idstr[0:17], [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]) )) % 11]
        if idstr[17] == code:
            return True
        else:
            return False
    except:
        return False
$$ LANGUAGE plpythonu immutable SECURITY DEFINER;

-- 返回手机号运营商 1 移动 2 联通 3 电信 0 错误
CREATE OR REPLACE FUNCTION py_get_carrier(phone text) RETURNS INT AS 
$$
try:
    phone_prefix = int(phone[0:3])
    prefixs_yd = [134,135,136,137,138,139,147,150,151,152,157,158,159,170,178,182,183,184,187,188,193,195,198,199]
    prefixs_lt = [130,131,132,145,155,156,168,170,171,175,176,185,186]
    prefixs_dx = [133,149,153,170,173,177,180,181,189]

    if phone_prefix in prefixs_yd:
        return 1
    elif phone_prefix in prefixs_lt:
        return 2
    elif phone_prefix in prefixs_dx:
        return 3
    else:
        return 0
except:
    return 0
$$ LANGUAGE plpythonu immutable SECURITY DEFINER

-- gen uid by random with revert
CREATE OR REPLACE FUNCTION py_gen_uid(phone text) RETURNS TEXT AS 
$$
    import random

    if not phone.isdigit() or len(phone) != 11:
        raise ValueError('phone number wrong for %s' % (phone))

    reverse = int(phone[6::-1])
    suffix = int(phone[7:11])

    randomSeed = random.randint(0, 100);
    if suffix < randomSeed:
        if suffix <= 0:
            randomSeed = 0
        else:
            randomSeed = random.randint(0, suffix);

# { 0:#0{1}x} 
# | | || | ||---  }  # End of format identifier
# | | || | |----  x  # hexadecimal number, using lowercase letters for a-f
# | | || |------ {1} # to a length of n characters (including 0x), defined by the second parameter
# | | ||--------  0  # fill with zeroes
# | | |---------  #  # use "0x" prefix
# | |-----------  0: # first parameter
# |-------------  {  # Format identifier
    hex_int_reverse = "{0:0{1}x}".format(reverse - randomSeed, 6).upper()
    hex_int_suffix = "{0:0{1}x}".format(suffix - randomSeed, 4).upper()
    hex_randomSeed = "{0:0{1}x}".format(randomSeed, 2).upper()
    return hex_int_reverse + hex_randomSeed + hex_int_suffix

$$ LANGUAGE plpythonu immutable SECURITY DEFINER



