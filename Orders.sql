--Orders t�bla l�trehoz�sa
CREATE TABLE orders (	
    oid NUMBER,
	pid NUMBER NOT NULL, 
	quantity NUMBER, 
    odate DATE,
    CHECK (quantity >= 0), 
    PRIMARY KEY (oid),
    CONSTRAINT fk_order FOREIGN KEY (pid) 
    REFERENCES product(pid)
)

--�j megrendel�s l�trehoz�sa
CREATE OR REPLACE PROCEDURE neworders( inproductname IN VARCHAR2, inquantity IN NUMBER, indate IN DATE) AS
    n_oid NUMBER;
    n_pid NUMBER;
    n_stock NUMBER;
BEGIN
    --A term�k azonos�t�j�nak lek�rdez�se, ha nincs ilyen azonos�t�, no_data_found kiv�telt kapunk.
    SELECT pid INTO n_pid FROM product WHERE  lower(product.name) = lower(inproductname);
    --�rt�kek ellen�rz�se
    IF inquantity <= 0 THEN
        dbms_output.put_line('A rendel�s t�tele nem lehet 0, vagy ann�l kissebb!');
    ELSE 
        SELECT pid, stock INTO n_pid, n_stock FROM product WHERE product.pid = n_pid;
        
        --Egy�ni els�dleges kulcs gener�l�sa
        SELECT MAX(oid) INTO n_oid FROM orders;
        IF n_oid IS NULL THEN
            n_oid := 0;
        END IF;
        n_oid := n_oid + 1;
        
        --Ha nincs el�g term�k rakt�ron a rendel�s sikertelen
        IF n_stock - inquantity < 0 THEN
          dbms_output.put_line('Nincs el�g term�k rakt�ron!');
        ELSE
            --Rendel�s besz�r�sa az Orders t�bl�ba
            INSERT INTO orders VALUES(n_oid, n_pid, inquantity, indate );
            --A term�k rakt�rk�szlet�nek friss�t�se a Product t�bl�ban
            UPDATE product SET product.stock = product.stock - inquantity WHERE pid=n_pid;
            dbms_output.put_line('Rendel�s k�sz!');
        END IF;
    END IF;
EXCEPTION
    --no_data_found kiv�tel kezel�se
    WHEN no_data_found THEN
        dbms_output.put_line('Nincs ilyen Termek');
END neworders;

--Random rendel�sek minden term�khez
DECLARE
    CURSOR productnames IS SELECT name FROM product;
    quantity NUMBER;
    day NUMBER(2);
    numoforders NUMBER;
    daystr VARCHAR2(10);
BEGIN
    FOR productname IN productnames LOOP
       numoforders:=10 + round(dbms_random.value()*20);
        FOR i IN 1..numoforders LOOP
            quantity:=10 + round(dbms_random.value()*100);
            day := 1+floor(dbms_random.value()*30);
            daystr := '2021-03-'||day;
            IF day < 10 THEN
                daystr := '2021-03-0'||day;
            END IF;
            neworders(productname.name, quantity, to_date(daystr,'YYYY-MM-DD') );
        END LOOP;
    END LOOP;
END;
/
