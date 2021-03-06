--Products t?bla l?trehoz?sa
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

--?j term?k l?trhoz?sa
CREATE OR REPLACE PROCEDURE newproduct( inname IN VARCHAR2, instock IN INT, inprice IN INT ) AS
    n_ok NUMBER;
    n_maxpid NUMBER;
    n_pid NUMBER;
    n_barcode NUMBER;
BEGIN
    SELECT COUNT(*) INTO n_ok FROM product WHERE product.name=inname;
    --Megadott ?rt?kek ellen?rz?se
    IF n_ok <> 0 THEN
        dbms_output.put_line('Ilyen term?k m?r l?tezik!');
    ELSIF instock < 0 THEN
        dbms_output.put_line('Nem lehet 0-n?l kevesebb a term?kek sz?ma!');
    ELSIF inprice < 0 THEN
        dbms_output.put_line('Nem lehet 0-n?l kevesebb a term?kek ?ra!');
    ELSE 
        --Egy?ni kulcs gener?l?sa
        SELECT MAX(product.pid) INTO n_maxpid FROM product;
        IF n_maxpid IS NULL THEN
            n_maxpid := 0;
        END IF;
        n_pid := n_maxpid + 1;
        --Vonalk?d gener?l?sa
        n_barcode := generatebarcode();
        --Term?k besz?r?sa a Product t?bl?ba
        INSERT INTO product VALUES (n_pid, inname, n_barcode, instock, inprice );
        dbms_output.put_line('Term?k besz?rva!');
    END IF;
END newproduct;

--L?tez? termk?k k?szlet n?vel?se
CREATE OR REPLACE PROCEDURE addproduct( inname IN VARCHAR2, instock IN INT ) AS
    n_pid INT:=NULL;
BEGIN
    SELECT pid INTO n_pid FROM product WHERE lower(product.name )= lower(inname);
    UPDATE product SET product.stock = product.stock + instock WHERE product.pid = n_pid;
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('Nincs ilyen term?k');
END addproduct;

--Random vonalk?d gener?l?sa
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

SET SERVEROUTPUT ON;

--Term?kek l?trehoz?sa
BEGIN
    newproduct('F?kt?rcsa',5000,20000);
    newproduct('Olajsz?r?',7000,5000);
    newproduct('Gy?jt?tekercs',15000,3500);
    newproduct('Ny?rigumi',5090,45000);
    newproduct('T?ligumi',8500,33000);
    newproduct('Gy?jt?gyertya',7000,2600);
    newproduct('Leveg?sz?r?',3000,2100);
END;
