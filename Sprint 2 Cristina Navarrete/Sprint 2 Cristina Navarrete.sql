#EXERCICI 1
#A partir dels documents adjunts (estructura_dades i dades_introduir), importa les dues taules.
#Mostra les característiques principals de l'esquema creat i explica les diferents taules i variables que existeixen. 
#Assegura't d'incloure un diagrama que il·lustri la relació entre les diferents taules i variables.

 -- Creamos la base de datos
    CREATE DATABASE IF NOT EXISTS transactions;
   
    
USE transactions;

    -- Creamos la tabla company
    CREATE TABLE IF NOT EXISTS company (
        id VARCHAR(15) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255)
    );


    -- Creamos la tabla transaction
    CREATE TABLE IF NOT EXISTS transaction (
        id VARCHAR(255) PRIMARY KEY,
        credit_card_id VARCHAR(15) REFERENCES credit_card(id),
        company_id VARCHAR(20), 
        user_id INT REFERENCES user(id),
        lat FLOAT,
        longitude FLOAT,
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN,
        FOREIGN KEY (company_id) REFERENCES company(id) 
    );

-- >Aquí ejectuamos el archivo N1-Ex.1__dades_introduir.sql (hay pantallazo en el pdf)



#EXERCICI 2
#Llistat dels països que estan generant vendes.
USE transactions;

SELECT company.country
FROM transaction
JOIN company
ON transaction.company_id = company.id 
WHERE transaction.declined = 0
GROUP BY company.country;


#Des de quants països es generen les vendes.
SELECT COUNT(DISTINCT company.country)
FROM transaction
JOIN company
ON company.id = transaction.company_id
WHERE transaction.declined = 0;

#Identifica la companyia amb la mitjana més gran de vendes.
SELECT company.id, company.company_name, ROUND(AVG(transaction.amount),2) AS media_ventas
FROM transaction
JOIN company
ON transaction.company_id = company.id 
WHERE transaction.declined = 0
GROUP BY company.id, company.company_name
ORDER BY media_ventas DESC
LIMIT 1;


#EXERCICI 3
#Mostra totes les transaccions realitzades per empreses d'Alemanya.
SELECT *
FROM transaction
WHERE  EXISTS (SELECT company.id
							FROM company
							WHERE country = 'Germany');

#Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT DISTINCT company.company_name
FROM company
JOIN transaction
ON company.id = transaction.company_id
WHERE transaction.amount> (SELECT AVG(transaction.amount)
							FROM transaction
                            WHERE transaction.declined = 0);
                  
#Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.      
SELECT company.company_name
FROM company
WHERE NOT EXISTS (SELECT transaction.company_id
					FROM transaction);
                   
  
-- Comprobamos la consulta anterior:
SELECT DISTINCT transaction.company_id
FROM transaction;
  
  
# EXERCICI 4   
#La teva tasca és dissenyar i crear una taula anomenada "credit_card" que emmagatzemi detalls crucials sobre les targetes de crèdit. 
#La nova taula ha de ser capaç d'identificar de manera única cada targeta i establir una relació adequada amb les altres dues taules
#("transaction" i "company"). Després de crear la taula serà necessari que ingressis la informació del document denominat 
#"dades_introduir_credit". Recorda mostrar el diagrama i realitzar una breu descripció d'aquest.

-- Creamos la tabla credit_card
CREATE TABLE IF NOT EXISTS credit_card (
    id VARCHAR(15) NOT NULL,
    iban VARCHAR(34),
    pan VARCHAR(20),
    pin VARCHAR(4),
    cvv VARCHAR(3),
    expiring_date VARCHAR(20),
    PRIMARY KEY (id)
);

-- > Aquí ejecutamos el archivo N1-Ex.4__datos_introducir_credit.sql para insertar los registros a la tabla credit_card.

-- Actualizamos la columna expiring_date a formato de DATE y para hacer la desactivamos el modo seguro temporalmente:
SET SQL_SAFE_UPDATES = 0;

-- Hacemos la conversión
UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%Y');

-- Activamos de nuevo el modo seguro
SET SQL_SAFE_UPDATES = 1;

-- Modificamos la tabla 'transaction' añadiendo reestrición foreign key
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);



#EXERCICI 5
#El departament de Recursos Humans ha identificat un error en el número de compte associat a la targeta de crèdit amb ID CcU-2938. 
#La informació que ha de mostrar-se per a aquest registre és: TR323456312213576817699999. 
#Recorda mostrar que el canvi es va realitzar.

-- Comprobamos el dato:
SELECT *
FROM credit_card
WHERE id ='CcU-2938';


-- Actualizo los datos:
UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

#Comprobamos el cambio:
SELECT*
FROM credit_card
WHERE id = 'CcU-2938';


#EXERCICI 6
#En la taula "transaction" ingressa una nova transacció amb la següent informació:

-- Insertamos el id en company b-9999 si no existe:
INSERT INTO company (id)
SELECT 'b-9999'
WHERE NOT EXISTS (
    SELECT company.id
    FROM company
    WHERE company.id = 'b-9999'
);
-- Insertamos el id en credit_card CcU-9999 si no existe:
INSERT INTO credit_card (id)
SELECT 'CcU-9999'
WHERE NOT EXISTS (
    SELECT credit_card.id
    FROM credit_card
    WHERE credit_card.id = 'CcU-9999'
);

-- Insertamos los datos en la tabla transaction:
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined) 
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', '9999', 829.999, -117.999, 111.11, '0');

-- Chequeamos el cambio:
SELECT*
FROM transaction
WHERE transaction.id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';


#EXERCICI 7
#Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card. Recorda mostrar el canvi realitzat.

-- Eliminamos columna:
alter table credit_card drop column pan;


-- Comprobamos que se ha modificado:
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'transactions'
AND TABLE_NAME = 'credit_card';

-- Comprobamos:
SELECT*
FROM credit_card;



#EXERCICI 8
#Dissenya una base de dades amb un esquema d'estrella que contingui, almenys 4 taules 

-- Creamos base de datos:
CREATE DATABASE IF NOT EXISTS online_sales;
  
USE online_sales;
 
-- Creamos la tabla companies:
CREATE TABLE IF NOT EXISTS companies (
    company_id VARCHAR(15) NOT NULL,
    company_name VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(100),
    country VARCHAR(100),
    website VARCHAR(255),
    merchant_category VARCHAR(100),
    merchant_price_position VARCHAR(50),
    PRIMARY KEY (company_id)
);
  
-- Creamos la tabla users:
CREATE TABLE IF NOT EXISTS users (
    id INT NOT NULL,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(100),
    birth_date VARCHAR(50),
    regiony VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255),
    signup_date DATE,
    user_segment VARCHAR(100),
    income_band VARCHAR(50),
    PRIMARY KEY (id)
);


-- Creamos la tabla credit_cards:
CREATE TABLE IF NOT EXISTS credit_cards (
    id VARCHAR(15) NOT NULL,
    user_id INT,
    iban VARCHAR(34),
    pan VARCHAR(20),
    pin VARCHAR(4),
    cvv VARCHAR(3),
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date VARCHAR(8),
    card_type VARCHAR(50),
    card_renewal_flag BOOLEAN,
    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);


-- Creamos la tabla transactions:
CREATE TABLE IF NOT EXISTS transactions (
id VARCHAR(100) NOT NULL,
card_id VARCHAR(15),
business_id VARCHAR(15),
timestamp DATETIME,
amount DECIMAL (10,2),
declined BOOLEAN,
product_ids VARCHAR(150),
user_id INT,
lat FLOAT,
longitude FLOAT,
discount_amount DECIMAL (10,2),
tax_amount DECIMAL (10,2),
shipping_amount DECIMAL (10,2),
channel VARCHAR(50),
campaign_id VARCHAR(20),
device_type VARCHAR(50),
is_international BOOLEAN,
decline_reason VARCHAR(20),
distance_km DECIMAL(10,2),
PRIMARY KEY (id),
FOREIGN KEY (card_id) REFERENCES credit_cards(id),
FOREIGN KEY (business_id) REFERENCES companies(company_id),
FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Mostramos la ruta segura para cargar archivos csv:
SHOW VARIABLES LIKE 'secure_file_priv';

-- Cargamos los datos para la tabla companies:
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

-- Cargamos los datos para la tabla users:
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- Cargamos los datos para la tabla credit_cards:
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

-- Cargamos los datos para la tabla transactions:
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'
IGNORE 1 ROWS;




#EXERCICI 9 Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules.
SELECT users.id, users.name, users.surname
FROM users
WHERE users.id IN (SELECT superior_ochenta.user_id
								FROM ( SELECT transactions.user_id,COUNT(*) as numero_transacciones
										FROM transactions
                                        WHERE transactions.declined = 0
										GROUP BY transactions.user_id
										HAVING numero_transacciones > 80) as superior_ochenta);
     
     
#EXERCICI 10 Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.
SELECT companies.company_name, credit_cards.iban, ROUND(AVG(transactions.amount),2) as media
FROM transactions
JOIN companies
ON transactions.business_id =companies.company_id 
JOIN credit_cards
ON transactions.card_id = credit_cards.id
WHERE companies.company_name = 'Donec Ltd'
AND transactions.declined = 0
GROUP BY credit_cards.iban
ORDER BY media DESC;


#NIVELL 2

#EXERCICI 1
#Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. Mostra la data de cada transacció juntament amb el total de les vendes.

SELECT DATE(timestamp), ROUND(SUM(amount),2) as suma
FROM transactions
WHERE transactions.declined = 0
GROUP BY DATE(timestamp)
ORDER BY suma DESC
LIMIT 5;

#EXERCICI 2
# Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions amb un valor comprès entre 350 i 400 euros i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. Ordena els resultats de major a menor quantitat.

SELECT companies.company_name, companies.phone, companies.country, transactions.timestamp, transactions.amount
FROM companies
JOIN transactions
ON companies.company_id = transactions.business_id
WHERE transactions.amount BETWEEN 350 AND 400
AND DATE(timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
AND transactions.declined = 0
ORDER BY amount DESC;


#EXERCICI 3
# Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses, però el departament de recursos humans és exigent i vol un llistat de les empreses on especifiquis si tenen igual o més de 400 transaccions o menys.

-- Utilizamos el CASE WHEN para  categorizar columnas.
SELECT transactions.business_id, companies.company_name, COUNT(*) as numero_transacciones, CASE
           WHEN COUNT(*) >= 400 THEN '400 o més'
           ELSE 'Menys de 400'
       END AS categoria
FROM transactions
JOIN companies
ON transactions.business_id = companies.company_id
WHERE transactions.declined = 0
GROUP BY transactions.business_id;

#EXERCICI 4
# Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.


-- Comprobamos el registro
SELECT *
FROM transactions
WHERE transactions.id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Eliminamos el registro:
DELETE FROM transactions
WHERE ID = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Comprobamos que se haya eliminado:
SELECT *
FROM transactions
WHERE transactions.id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

#EXERCICI 5
#La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives. 
#S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions. 
#Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent informació: Nom de la companyia. 
#Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia. Presenta la vista creada, ordenant 
#les dades de major a menor mitjana de compra

-- Creamos la vista VistaMarketing:
CREATE VIEW VistaMarketing AS
SELECT companies.company_name, companies.phone, companies.country, AVG(transactions.amount) as Media
FROM companies
JOIN transactions
ON companies.company_id = transactions.business_id 
GROUP BY companies.company_name, companies.phone, companies.country
ORDER BY Media DESC;

-- Comprobamos la vista:
SELECT * 
FROM online_sales.vistamarketing;

#NIVELL 3
#EXERCICI 1
#Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes transaccions han estat declinades 
#aleshores és inactiu, si almenys una no és rebutjada aleshores és actiu. Partint d’aquesta taula respon:
#Quantes targetes estan actives?

-- En primer lugar creamos la tabla desde una consulta utilizando CASE WHEN para categorizar columnas y el ROW_NUMBER() OVER (PARTITION BY..) 
-- para añadir número a las filas por cada card_id, luego con el WHERE seleccionamos las tres últimas transacciones.
CREATE TABLE IF NOT EXISTS estado_targetas as
SELECT transacciones.card_id, CASE
						WHEN SUM(transacciones.declined) = 3  THEN 'Inactiu'
						ELSE 'Actiu'
                        END AS estado
FROM (SELECT card_id, declined, ROW_NUMBER() OVER ( PARTITION BY card_id
						ORDER BY timestamp DESC) as numero_fila 
						FROM transactions) as transacciones
WHERE transacciones.numero_fila IN (1,2,3)
GROUP BY card_id;

-- Chequeamos la tabla:
SELECT*
FROM estado_targetas;

-- Cuando ya tenemos la tabla, hacemos la consulta:
SELECT COUNT(card_id)
FROM estado_targetas
WHERE estado = 'Actiu';

#EXERCICI 2
#Crea una taula amb la qual puguem unir les dades de l'arxiu de products.csv amb la base de dades creada (ja que fins ara no podíem fer-ho),
#tenint en compte que des de transaction tens product_ids. 

#Genera la següent consulta:
#Necessitem conèixer el nombre de vegades que s'ha venut cada producte.

-- Primero creamos la tabla products dentro de la base de datos online_sales:

USE online_sales;

-- Creamos la tabla products:
CREATE TABLE IF NOT EXISTS products (
id VARCHAR (10) NOT NULL,
product_name VARCHAR (100),
price DECIMAL (10,2),
colour VARCHAR(20),
weight DECIMAL (10,1),
warehouse_id VARCHAR(50),
category VARCHAR(50),
brand VARCHAR(50),
cost DECIMAL (10,2),
launch_date DATE,
PRIMARY KEY (id));

-- Cargamos los datos del fichero N1-Ex.8__products.csv' en la ruta que nos ha dado MySQL
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

-- Comprobamos los datos cargados:
SELECT *
FROM products;

-- Creamos la tabla desde una consulta:
CREATE TABLE IF NOT EXISTS transaction_products AS
SELECT transactions.id, productos_separados.product_id
FROM transactions
JOIN JSON_TABLE(

    CONCAT('[', transactions.product_ids, ']'),
    '$[*]' COLUMNS (
        product_id INT PATH '$'
    )
) AS productos_separados;

-- Comprobamos la tabla transaction_products:
SELECT*
FROM transaction_products;

-- Hacemos la consulta para responder a la pregunta de cuántas veces se ha vendido cada producto.
SELECT
    products.id,
    products.product_name,
    COUNT(transaction_products.id) AS veces_vendido
FROM transaction_products
JOIN products
    ON transaction_products.product_id = products.id
GROUP BY
    products.id,
    products.product_name;