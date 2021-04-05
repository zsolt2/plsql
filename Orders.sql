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

CREATE OR REPLACE PROCEDURE neworders( inproductname IN VARCHAR2, inquantity IN NUMBER, indate IN DATE) AS
    n_oid NUMBER;
    n_pid NUMBER;
    n_stock NUMBER;
BEGIN
    SELECT pid INTO n_pid FROM product WHERE  lower(product.name) = lower(inproductname);
    IF inquantity < 0 THEN
        dbms_output.put_line('A rendelés tétele nem lehet 0-nál kissebb!');
    ELSE 
        SELECT pid, stock INTO n_pid, n_stock FROM product WHERE product.pid = n_pid;
        SELECT MAX(oid) INTO n_oid FROM orders;
        IF n_oid IS NULL THEN
            n_oid := 0;
        END IF;
        n_oid := n_oid + 1;
        IF n_stock - inquantity < 0 THEN
          dbms_output.put_line('Nincs elég termék a raktáron!');
        ELSE
            INSERT INTO orders VALUES(n_oid, n_pid, inquantity, indate );
            UPDATE product SET product.stock = product.stock - inquantity WHERE pid=n_pid;
            dbms_output.put_line('Rendelés kész!');
        END IF;
    END IF;
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('Nincs ilyen Termek');
END neworders;

--Random rendelések minden termékhez
DECLARE
    CURSOR productnames IS SELECT name FROM product;
    quantity NUMBER;
    day NUMBER(2);
    numoforders NUMBER;
    month NUMBER;
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
