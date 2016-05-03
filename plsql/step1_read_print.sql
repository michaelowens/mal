@io.sql
@types.sql
@reader.sql
@printer.sql

CREATE OR REPLACE PACKAGE mal IS

FUNCTION MAIN(args varchar DEFAULT '()') RETURN integer;

END mal;
/

CREATE OR REPLACE PACKAGE BODY mal IS

FUNCTION MAIN(args varchar DEFAULT '()') RETURN integer IS
    M         mem_type;                 -- general mal value memory pool
    H         types.map_entry_table;    -- hashmap memory pool
    line      varchar2(4000);

    -- read
    FUNCTION READ(line varchar) RETURN integer IS
    BEGIN
        RETURN reader.read_str(M, H, line);
    END;

    -- eval
    FUNCTION EVAL(ast integer, env varchar) RETURN integer IS
    BEGIN
        RETURN ast;
    END;

    -- print
    FUNCTION PRINT(exp integer) RETURN varchar IS
    BEGIN
        RETURN printer.pr_str(M, H, exp);
    END;

    -- repl
    FUNCTION REP(line varchar) RETURN varchar IS
    BEGIN
        RETURN PRINT(EVAL(READ(line), ''));
    END;

BEGIN
    -- initialize memory pools
    M := types.mem_new();
    H := types.map_entry_table();

    WHILE true LOOP
        BEGIN
            line := stream_readline('user> ', 0);
            IF line IS NULL THEN CONTINUE; END IF;
            IF line IS NOT NULL THEN
                stream_writeline(REP(line));
            END IF;

            EXCEPTION WHEN OTHERS THEN
                IF SQLCODE = -20001 THEN  -- io streams closed
                    RETURN 0;
                END IF;
                stream_writeline('Error: ' || SQLERRM);
                stream_writeline(dbms_utility.format_error_backtrace);
        END;
    END LOOP;
END;

END mal;
/
show errors;

quit;