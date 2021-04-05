CREATE TABLE product (	
    pid NUMBER, 
	name VARCHAR2(100) UNIQUE, 
	barcode NUMBER(13), 
	stock NUMBER, 
	price NUMBER, 
    CHECK (stock >= 0) ENABLE, 
    CHECK (price >= 0) ENABLE, 
    PRIMARY KEY (pid)
)

CREATE OR REPLACE FUNCTION generatebarcode RETURN NUMBER AS
    c_kod VARCHAR(13) := '599';
    c_sum NUMBER := 41;
    c_rand NUMBER;
BEGIN
    FOR i IN 1..9 LOOP 
        c_rand := floor( dbms_random.value() * 10 );
        IF i MOD 2 = 0 THEN
            c_sum := c_sum + c_rand;
        ELSE
            c_sum := c_sum + c_rand * 3;
        END IF;
        c_kod := c_kod||c_rand;
    END LOOP;
    c_sum := 10 - (c_sum MOD 10);
    IF c_sum = 10  THEN
        c_sum := 0;
    END IF;
    c_kod := c_kod||c_sum;
    RETURN to_number(c_kod);
END generatebarcode;

CREATE OR REPLACE PROCEDURE newproduct( inname IN VARCHAR2, instock IN INT, inprice IN INT ) AS
    n_ok NUMBER;
    n_maxpid NUMBER;
    n_pid NUMBER;
    n_barcode NUMBER;
BEGIN
    SELECT COUNT(*) INTO n_ok FROM product WHERE product.name=inname;
    IF n_ok <> 0 THEN
        dbms_output.put_line('Ilyen termék már létezik!');
    ELSIF instock < 0 THEN
        dbms_output.put_line('Nem lehet 0-nal kevesebb a termekek szama!');
    ELSIF inprice < 0 THEN
        dbms_output.put_line('Nem lehet 0-nal kevesebb a termekek ara!');
    ELSE 
        SELECT MAX(product.pid) INTO n_maxpid FROM product;
        IF n_maxpid IS NULL THEN
            n_maxpid := 0;
        END IF;
        n_pid := n_maxpid + 1;
        n_barcode := generatebarcode();
        
        INSERT INTO product VALUES (n_pid, inname, n_barcode, instock, inprice );
        dbms_output.put_line('Termek beszurva!');
    END IF;
END newproduct;

CREATE OR REPLACE PROCEDURE addproduct( inname IN VARCHAR2, instock IN INT ) AS
    n_pid INT:=NULL;
BEGIN
    SELECT pid INTO n_pid FROM product WHERE lower(product.name )= lower(inname);
    UPDATE product SET product.stock = product.stock + instock WHERE product.pid = n_pid;
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('Nincs ilyen Termek');
END addproduct;

SET SERVEROUTPUT ON;

BEGIN
    newproduct('Alma',5000,20);
    newproduct('Körte',7000,10);
    newproduct('Szilva',15000,30);
    newproduct('Répa',5090,45);
    newproduct('Karalábé',8500,33);
    newproduct('Paprika',7000,26);
    newproduct('Paradicsom',3000,11);
END;
