--HTML fájl létrehozása
CREATE OR REPLACE PROCEDURE printresultstofile AS 
    --Összes termék lekérdezése
    CURSOR productnames IS SELECT * FROM product;
    outfile utl_file.file_type;
BEGIN
    --Output fájl megnyitása
    outfile := utl_file.fopen('OTPUTDIR', 'results.html' , 'W');
    
    utl_file.put_line(outfile,'<html>');
    utl_file.put_line(outfile, '<head><meta charset="UTF-8"></head>');
    utl_file.put_line(outfile,'<body>');
    utl_file.put_line(outfile,'<H1>Öszegzés</H1>');
    FOR p IN productnames LOOP
        --Termék adatai
        utl_file.put_line(outfile, '<H2>'||p.name||'</H2>');
        utl_file.put_line(outfile,'<div>');
        utl_file.put_line(outfile, 'Raktáron: '||p.stock);
        utl_file.put_line(outfile,'<br>');
        utl_file.put_line(outfile, 'Ár: '||p.price||' HUF');
        utl_file.put_line(outfile,'<br>');
        utl_file.put_line(outfile, 'Vonalkód: '||p.barcode);
        utl_file.put_line(outfile,'<br>');
        utl_file.put_line(outfile,'</div>');
        utl_file.put_line(outfile,'<div>');
        utl_file.put_line(outfile,'<h3>Napi rendelések</h3>');
        --Diagram
        makechart( p.name, outfile );
        utl_file.put_line(outfile,'</div>');
        utl_file.put_line(outfile,'<hr>');
    END LOOP;
    
    utl_file.put_line(outfile,'</body>');
    utl_file.put_line(outfile,'</html>');
    utl_file.fclose(outfile);
END printresultstofile;

CREATE OR REPLACE PROCEDURE makechart(inproductname IN VARCHAR2, outfile IN utl_file.file_type ) AS
    --Dátdumok és napi rednelések összegenék lekérdezése
    CURSOR c_orders IS SELECT orders.odate, SUM(orders.quantity) sumq FROM orders JOIN product ON orders.pid=product.pid WHERE product.name=inproductname GROUP BY orders.odate ORDER BY orders.odate;
    n_height NUMBER := 500;
    n_width NUMBER := 1000;
    n_chartheight NUMBER := n_height - 100;
    n_maxorders NUMBER;
    n_minorders NUMBER;
    d_mindate DATE;
    d_maxdate DATE;
    n_mindate NUMBER;
    n_maxdate NUMBER;
    n_barx NUMBER;
    n_barheight NUMBER;
    n_currdate NUMBER;
    n_barwidth NUMBER:=20;
BEGIN
    --Legkisebb és legnagyobb dátum lekérdezése
    SELECT MAX(orders.odate), MIN(orders.odate) INTO d_maxdate, d_mindate  FROM orders JOIN product ON orders.pid=product.pid WHERE product.name=inproductname;
    --Legkisebb és legnagyobb rendelések számának lekérdezése
    SELECT MAX(SUM(orders.quantity)), MIN(SUM(orders.quantity)) INTO n_maxorders, n_minorders FROM  orders JOIN product ON orders.pid=product.pid WHERE product.name=inproductname GROUP BY orders.odate;
    
    n_minorders := round(n_minorders - n_minorders * 0.1); --A szélsõértékek 10 százalékkal eltérnek, hogy ne 0-nál kezdõdjönek az oszlopok, és ne érjenek az ábra tetejéhez
    n_maxorders := round(n_maxorders + n_maxorders * 0.1);
    n_maxdate := (d_maxdate - d_mindate);
    
    utl_file.put_line(outfile, '<svg height="'||(n_height)||'" width="'||n_width||' margin">');
    --Diagram vonalainak rajzolása
    drawchartlines(n_minorders, n_maxorders,n_width, n_chartheight, outfile);
    
    --Diagram oszlopainak rajzolása
    FOR a IN c_orders LOOP
        n_currdate := (a.odate - d_mindate);
        n_barheight := floor(map(  n_minorders, n_maxorders, 10 ,  n_chartheight -10, a.sumq ));
        n_barx := round(map(0, n_maxdate,  45 , n_width-10, n_currdate));
        drawrect(n_barx, n_chartheight - n_barheight, n_barwidth, n_barheight, outfile);
        writetext(n_barx ,n_chartheight - n_barheight - 10, a.sumq, outfile );
        writedate(n_barx, n_chartheight + 15, a.odate, outfile);
    END LOOP;
    --SVG tag lezárása
    utl_file.put_line(outfile, '</svg>');
END makechart;

--Diagram vonalainak rajzolása
CREATE OR REPLACE PROCEDURE drawchartLines(inmin IN NUMBER, inmax IN NUMBER,inwidth in number, inheight in Number, outfile IN utl_file.file_type ) AS
    n_height NUMBER := inheight;
    n_width NUMBER := inwidth;
    n_min NUMBER := inmin - inmin*0.1;
    n_scale NUMBER := (inmax - n_min)/10; --Az intervallumot feloszjuk 10 részre, 10 vonalat fogunk rajzolni
    n_iterator NUMBER := n_min;
    n_y NUMBER;
BEGIN
    WHILE n_iterator <= inmax LOOP
        n_y := ceil(map( n_min, inmax,10, n_height, n_iterator));
        writetext( 1 , n_y + 7, round(inmax + n_min - n_iterator), outfile );
        drawline( 40 , n_y , n_width + 20, n_y , outfile ); 
        n_iterator := n_iterator + n_scale;
    END LOOP;
END drawchartLines;

--lineáris interpoláció egyik intervllumból a másikba
CREATE OR REPLACE FUNCTION map( oldmin IN NUMBER, oldmax IN NUMBER, newmin IN NUMBER, newmax IN NUMBER, oldvalue IN NUMBER) RETURN NUMBER AS
    n_oldrange NUMBER := oldmax - oldmin;
    n_newrange NUMBER := newmax - newmin;
    n_newvalue NUMBER;
BEGIN
    n_newvalue := (((oldvalue - oldmin) * n_newrange) / n_oldrange) + newmin;
    RETURN n_newvalue;
END;

CREATE OR REPLACE PROCEDURE drawline( x1 IN NUMBER, y1 IN NUMBER,  x2 IN NUMBER, y2 IN NUMBER, outfile IN utl_file.file_type) AS
BEGIN
    utl_file.put_line(outfile, '<line x1="'||x1||'" y1="'||y1||'" x2="'||x2||'" y2="'||y2||'" style="stroke:rgb(0,0,0);stroke-width:2" ></line>');
END drawline;

CREATE OR REPLACE PROCEDURE writetext( x IN NUMBER, y IN NUMBER, textnumber IN NUMBER ,outfile IN utl_file.file_type) AS
BEGIN
    utl_file.put_line(outfile, '<text x="'||x||'" y="'||y||'" fill="black">'||textnumber||'</text>');
END writetext;

CREATE OR REPLACE PROCEDURE writeDate( x IN NUMBER, y IN NUMBER, indate IN Date ,outfile IN utl_file.file_type) AS
BEGIN
    utl_file.put_line(outfile, '<text x="'||x||'" y="'||y||'" fill="black" transform="rotate(45 '||x||','||y||')" font-size="12px">'||to_char(indate,'YYYY-MM-DD')||'</text>');
END writeDate;

CREATE OR REPLACE PROCEDURE drawrect( x IN NUMBER, y IN NUMBER, width IN NUMBER, height IN NUMBER, outfile IN utl_file.file_type) AS 
BEGIN
    utl_file.put_line(outfile, '<rect x="'||x||'" y="'||y||'" width="'||width||'" height="'||height||'" style="fill:blue;stroke:rgb(0,0,0);stroke-width:2" ></rect>');
END drawrect;

BEGIN
    --Directory objectum létrehozása az adatbázis rendszerben
    EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY otputdir AS ''C:\results''';
    EXECUTE IMMEDIATE 'GRANT READ ON DIRECTORY otputdir TO PUBLIC';
    --Összegzés létrehozása
    printresultstofile;
END;
