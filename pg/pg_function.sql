
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

