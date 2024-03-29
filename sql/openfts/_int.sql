-- Create the user-defined type for the 1-D integer arrays (_int4)
-- 
BEGIN TRANSACTION;

--
-- External C-functions for R-tree methods
--

-- Comparison methods

CREATE FUNCTION _int_contains(_int4, _int4) RETURNS bool
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

INSERT INTO pg_description (objoid, description)
   SELECT oid, 'contains'::text
   FROM pg_proc
   WHERE proname = '_int_contains'::name;

CREATE FUNCTION _int_contained(_int4, _int4) RETURNS bool
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

INSERT INTO pg_description (objoid, description)
   SELECT oid, 'contained in'::text
   FROM pg_proc
   WHERE proname = '_int_contained'::name;

CREATE FUNCTION _int_overlap(_int4, _int4) RETURNS bool
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

INSERT INTO pg_description (objoid, description)
   SELECT oid, 'overlaps'::text
   FROM pg_proc
   WHERE proname = '_int_overlap'::name;

CREATE FUNCTION _int_same(_int4, _int4) RETURNS bool
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

INSERT INTO pg_description (objoid, description)
   SELECT oid, 'same as'::text
   FROM pg_proc
   WHERE proname = '_int_same'::name;

CREATE FUNCTION _int_different(_int4, _int4) RETURNS bool
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

INSERT INTO pg_description (objoid, description)
   SELECT oid, 'different'::text
   FROM pg_proc
   WHERE proname = '_int_different'::name;

-- support routines for indexing

CREATE FUNCTION _int_union(_int4, _int4) RETURNS _int4
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION _int_inter(_int4, _int4) RETURNS _int4
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

--
-- OPERATORS
--

CREATE OPERATOR && (
   LEFTARG = _int4, RIGHTARG = _int4, PROCEDURE = _int_overlap,
   COMMUTATOR = '&&',
   RESTRICT = contsel, JOIN = contjoinsel
);

--CREATE OPERATOR = (
--   LEFTARG = _int4, RIGHTARG = _int4, PROCEDURE = _int_same,
--   COMMUTATOR = '=', NEGATOR = '<>',
--   RESTRICT = eqsel, JOIN = eqjoinsel,
--   SORT1 = '<', SORT2 = '<'
--);

CREATE OPERATOR <> (
   LEFTARG = _int4, RIGHTARG = _int4, PROCEDURE = _int_different,
   COMMUTATOR = '<>', NEGATOR = '=',
   RESTRICT = neqsel, JOIN = neqjoinsel
);

CREATE OPERATOR @ (
   LEFTARG = _int4, RIGHTARG = _int4, PROCEDURE = _int_contains,
   COMMUTATOR = '~', RESTRICT = contsel, JOIN = contjoinsel
);

CREATE OPERATOR ~ (
   LEFTARG = _int4, RIGHTARG = _int4, PROCEDURE = _int_contained,
   COMMUTATOR = '@', RESTRICT = contsel, JOIN = contjoinsel
);


-- define the GiST support methods
CREATE FUNCTION g_int_consistent(opaque,_int4,int4) RETURNS bool
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_int_compress(opaque) RETURNS opaque 
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_int_decompress(opaque) RETURNS opaque 
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_int_penalty(opaque,opaque,opaque) RETURNS opaque
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_int_picksplit(opaque, opaque) RETURNS opaque
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_int_union(bytea, opaque) RETURNS _int4 
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_int_same(_int4, _int4, opaque) RETURNS opaque 
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';


-- register the default opclass for indexing
INSERT INTO pg_opclass (opcname, opcdeftype)
   SELECT 'gist__int_ops', oid
   FROM pg_type
   WHERE typname = '_int4';


-- get the comparators for _intments and store them in a tmp table
SELECT o.oid AS opoid, o.oprname
INTO TABLE _int_ops_tmp
FROM pg_operator o, pg_type t
WHERE o.oprleft = t.oid and o.oprright = t.oid
   and t.typname = '_int4';

-- make sure we have the right operators
-- SELECT * from _int_ops_tmp;

-- using the tmp table, generate the amop entries 

-- _int_overlap
INSERT INTO pg_amop (amopid, amopclaid, amopopr, amopstrategy)
   SELECT am.oid, opcl.oid, c.opoid, 3
   FROM pg_am am, pg_opclass opcl, _int_ops_tmp c
   WHERE amname = 'gist' and opcname = 'gist__int_ops' 
      and c.oprname = '&&';

-- _int_same
INSERT INTO pg_amop (amopid, amopclaid, amopopr, amopstrategy)
   SELECT am.oid, opcl.oid, c.opoid, 6
   FROM pg_am am, pg_opclass opcl, _int_ops_tmp c
   WHERE amname = 'gist' and opcname = 'gist__int_ops' 
      and c.oprname = '=';

-- _int_contains
INSERT INTO pg_amop (amopid, amopclaid, amopopr, amopstrategy)
   SELECT am.oid, opcl.oid, c.opoid, 7
   FROM pg_am am, pg_opclass opcl, _int_ops_tmp c
   WHERE amname = 'gist' and opcname = 'gist__int_ops' 
      and c.oprname = '@';

-- _int_contained
INSERT INTO pg_amop (amopid, amopclaid, amopopr, amopstrategy)
   SELECT am.oid, opcl.oid, c.opoid, 8
   FROM pg_am am, pg_opclass opcl, _int_ops_tmp c
   WHERE amname = 'gist' and opcname = 'gist__int_ops' 
      and c.oprname = '~';

DROP TABLE _int_ops_tmp;


-- add the entries to amproc for the support methods
-- note the amprocnum numbers associated with each are specific!

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 1
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__int_ops'
      and proname = 'g_int_consistent';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 2
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__int_ops'
      and proname = 'g_int_union';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 3
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__int_ops'
      and proname = 'g_int_compress';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 4
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__int_ops'
      and proname = 'g_int_decompress';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 5
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__int_ops'
      and proname = 'g_int_penalty';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 6
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__int_ops'
      and proname = 'g_int_picksplit';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 7
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__int_ops'
      and proname = 'g_int_same';


---------------------------------------------
-- intbig
---------------------------------------------
-- define the GiST support methods
CREATE FUNCTION g_intbig_consistent(opaque,_int4,int4) RETURNS bool
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_intbig_compress(opaque) RETURNS opaque 
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_intbig_decompress(opaque) RETURNS opaque 
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_intbig_penalty(opaque,opaque,opaque) RETURNS opaque
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_intbig_picksplit(opaque, opaque) RETURNS opaque
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_intbig_union(bytea, opaque) RETURNS _int4 
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

CREATE FUNCTION g_intbig_same(_int4, _int4, opaque) RETURNS opaque 
	AS '/usr/local/pgsql/lib/contrib/lib_int.so.1.0' LANGUAGE 'c';

-- register the default opclass for indexing
INSERT INTO pg_opclass (opcname, opcdeftype)
   values ( 'gist__intbig_ops', 0 );


-- get the comparators for _intments and store them in a tmp table
SELECT o.oid AS opoid, o.oprname
INTO TABLE _int_ops_tmp
FROM pg_operator o, pg_type t
WHERE o.oprleft = t.oid and o.oprright = t.oid
   and t.typname = '_int4';

-- make sure we have the right operators
-- SELECT * from _int_ops_tmp;

-- using the tmp table, generate the amop entries 

-- _int_overlap
INSERT INTO pg_amop (amopid, amopclaid, amopopr, amopstrategy)
   SELECT am.oid, opcl.oid, c.opoid, 3
   FROM pg_am am, pg_opclass opcl, _int_ops_tmp c
   WHERE amname = 'gist' and opcname = 'gist__intbig_ops' 
      and c.oprname = '&&';

-- _int_contains
INSERT INTO pg_amop (amopid, amopclaid, amopopr, amopstrategy)
   SELECT am.oid, opcl.oid, c.opoid, 7
   FROM pg_am am, pg_opclass opcl, _int_ops_tmp c
   WHERE amname = 'gist' and opcname = 'gist__intbig_ops' 
      and c.oprname = '@';

-- _int_contained
INSERT INTO pg_amop (amopid, amopclaid, amopopr, amopstrategy)
   SELECT am.oid, opcl.oid, c.opoid, 8
   FROM pg_am am, pg_opclass opcl, _int_ops_tmp c
   WHERE amname = 'gist' and opcname = 'gist__intbig_ops' 
      and c.oprname = '~';

DROP TABLE _int_ops_tmp;


-- add the entries to amproc for the support methods
-- note the amprocnum numbers associated with each are specific!

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 1
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__intbig_ops'
      and proname = 'g_intbig_consistent';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 2
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__intbig_ops'
      and proname = 'g_intbig_union';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 3
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__intbig_ops'
      and proname = 'g_intbig_compress';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 4
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__intbig_ops'
      and proname = 'g_intbig_decompress';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 5
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__intbig_ops'
      and proname = 'g_intbig_penalty';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 6
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__intbig_ops'
      and proname = 'g_intbig_picksplit';

INSERT INTO pg_amproc (amid, amopclaid, amproc, amprocnum)
   SELECT am.oid, opcl.oid, pro.oid, 7
   FROM pg_am am, pg_opclass opcl, pg_proc pro
   WHERE  amname = 'gist' and opcname = 'gist__intbig_ops'
      and proname = 'g_intbig_same';

END TRANSACTION;
