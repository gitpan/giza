--drop function relkov (float,float,int4, int4, _int4); 
--drop function relor (float,float,int4, int4, _int4); 
create function relor (float, float, int4, int4, _int4)
returns float8
as '/usr/local/pgsql/lib/contrib/relkov.so'
LANGUAGE 'C';
create function relkov (float, float, int4, int4, _int4)
returns float8
as '/usr/local/pgsql/lib/contrib/relkov.so'
LANGUAGE 'C';
