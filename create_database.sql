DROP SCHEMA IF EXISTS fh CASCADE;
CREATE SCHEMA fh;
SET search_path TO fh;


DROP TABLE IF EXISTS Pais CASCADE;
CREATE TABLE Pais (
	codigo CHAR(3),
	nome VARCHAR(32) NOT NULL,
	CONSTRAINT pais_pk PRIMARY KEY (codigo)
);

DROP TABLE IF EXISTS Cidade CASCADE;
CREATE TABLE Cidade (
	pais CHAR(3),
	nome VARCHAR(32),
	CONSTRAINT cidade_pk PRIMARY KEY (pais, nome),
	CONSTRAINT pais_fk FOREIGN KEY (pais) REFERENCES Pais(codigo)
);

DROP TABLE IF EXISTS TipoNavio CASCADE;
CREATE TABLE TipoNavio (
	tipo VARCHAR(64),
	CONSTRAINT tipo_pk PRIMARY KEY (tipo)
);

DROP TABLE IF EXISTS Modelo CASCADE;
CREATE TABLE Modelo (
	codigo VARCHAR(128),
	tamanho REAL NOT NULL,
	velocidade_media REAL NOT NULL,
	capacidade REAL NOT NULL,
	tipo VARCHAR(64) NOT NULL,
	CONSTRAINT modelo_pk PRIMARY KEY (codigo),
	CONSTRAINT tipo_fk FOREIGN KEY (tipo) REFERENCES TipoNavio(tipo)
);

DROP TABLE IF EXISTS Navio CASCADE;
CREATE TABLE Navio (
	codigo INTEGER,
	nome VARCHAR(128) NOT NULL,
	pais_origem CHAR(3) NOT NULL,
	modelo VARCHAR(64) NOT NULL,
	CONSTRAINT navio_pk PRIMARY KEY (codigo),
	CONSTRAINT modelo_fk FOREIGN KEY (modelo) REFERENCES Modelo(codigo),
	CONSTRAINT pais_fk FOREIGN KEY (pais_origem) REFERENCES Pais(codigo)
);

DROP TABLE IF EXISTS Porto CASCADE;
CREATE TABLE Porto (
	codigo CHAR(3),
	pais CHAR(3) NOT NULL,
	cidade VARCHAR(32) NOT NULL,
	CONSTRAINT porto_pk PRIMARY KEY (codigo),
	CONSTRAINT cidade_fk FOREIGN KEY (pais, cidade) REFERENCES Cidade(pais, nome)
);

DROP TABLE IF EXISTS Rota CASCADE;
CREATE TABLE Rota (
	origem CHAR(3),
	destino CHAR(3),
	distancia REAL NOT NULL,
	CONSTRAINT rota_pk PRIMARY KEY (origem, destino),
	CONSTRAINT origem_fk FOREIGN KEY (origem) REFERENCES Porto(codigo),
	CONSTRAINT destino_fk FOREIGN KEY (destino) REFERENCES Porto(codigo)
);

DROP TABLE IF EXISTS CategoriaProduto CASCADE;
CREATE TABLE CategoriaProduto (
	id INTEGER,
	nome VARCHAR(64) NOT NULL,
	preco_para_movimentar REAL NOT NULL,
	CONSTRAINT categoria_produto_pk PRIMARY KEY (id),
	CONSTRAINT preco_para_movimentar_ck CHECK (preco_para_movimentar >= 0)
);

DROP TABLE IF EXISTS Produto CASCADE;
CREATE TABLE Produto (
	id INTEGER,
	nome VARCHAR(64) NOT NULL,
	categoria_id INTEGER NOT NULL,
	CONSTRAINT produto_pk PRIMARY KEY (id),
	CONSTRAINT categoria_fk FOREIGN KEY (categoria_id) REFERENCES CategoriaProduto(id)
);

DROP TABLE IF EXISTS Carga CASCADE;
CREATE TABLE Carga (
	id INTEGER,
	peso REAL NOT NULL,
	produto_id INTEGER NOT NULL,
	porto_id VARCHAR(3),
	CONSTRAINT carga_pk PRIMARY KEY (id),
	CONSTRAINT porto_carga_pk FOREIGN KEY (porto_id) REFERENCES Porto(codigo),
	CONSTRAINT produto_fk FOREIGN KEY (produto_id) REFERENCES Produto(id)
);

DROP TABLE IF EXISTS TipoNavioTransporta CASCADE;
CREATE TABLE TipoNavioTransporta (
	tipo_navio VARCHAR(64),
	categoria_id INTEGER,
	CONSTRAINT tipo_navio_transporta_pk PRIMARY KEY (tipo_navio, categoria_id),
	CONSTRAINT tipo_navio_fk FOREIGN KEY (tipo_navio) REFERENCES TipoNavio(tipo),
	CONSTRAINT categoria_fk FOREIGN KEY (categoria_id) REFERENCES CategoriaProduto(id)
);


INSERT INTO Pais VALUES
	('BRA', 'Brasil'),
	('USA', 'Estados Unidos'),
	('CHN', 'China'),
	('ESP', 'Espanha'),
	('FRA', 'França'),
	('ARG', 'Argentina');

INSERT INTO Cidade VALUES
	('BRA', 'Rio de Janeiro'),
	('BRA', 'Santos'),
	('USA', 'Miami'),
	('CHN', 'Xangai'),
	('ESP', 'Barcelona'),
	('FRA', 'Marselha'),
	('ARG', 'Buenos Aires');

INSERT INTO Porto VALUES
	('RJ1', 'BRA', 'Rio de Janeiro'),
	('SAN', 'BRA', 'Santos'),
	('MIA', 'USA', 'Miami'),
	('SHA', 'CHN', 'Xangai'),
	('BAR', 'ESP', 'Barcelona'),
	('MAR', 'FRA', 'Marselha'),
	('BUE', 'ARG', 'Buenos Aires');

INSERT INTO Rota VALUES
	('RJ1', 'MIA', 7200.0),
	('MIA', 'SHA', 12000.0),
	('SHA', 'SAN', 14500.0),
	('SAN', 'RJ1', 350.0),
	('SAN', 'BAR', 8400.0),
	('BAR', 'MAR', 500.0),
	('MAR', 'SHA', 10000.0),
	('BUE', 'SAN', 2000.0),
	('BUE', 'MIA', 7000.0),
	('MAR', 'BUE', 11000.0),
	('MIA', 'BAR', 7500.0);

INSERT INTO CategoriaProduto (id, nome, preco_para_movimentar) VALUES
	(1, 'Eletrônicos', 50.00),
	(2, 'Alimentos', 10.00),
	(3, 'Vestuário', 20.00),
	(4, 'Móveis', 100.00),
	(5, 'Livros', 5.00);

INSERT INTO Produto (id, nome, categoria_id) VALUES
	(1, 'Smartphone', 1),
	(2, 'Notebook', 1),
	(3, 'Arroz 5kg', 2),
	(4, 'Camiseta', 3),
	(5, 'Sofá 3 lugares', 4),
	(6, 'Livro de Romance', 5),
	(7, 'Jaqueta de Couro', 3),
	(8, 'Mesa de Escritório', 4),
	(9, 'Chocolate 100g', 2),
	(10, 'Carregador USB', 1);

INSERT INTO Carga (id, peso, produto_id, porto_id) VALUES
	(1, 500.0, 1, 'RJ1'),
	(2, 1200.0, 2, 'SAN'),
	(3, 2000.0, 3, 'BUE'),
	(4, 300.0, 4, 'MIA'),
	(5, 8000.0, 5, 'MAR'),
	(6, 150.0, 6, 'BAR'),
	(7, 700.0, 7, 'SHA'),
	(8, 5000.0, 8, 'SHA'),
	(9, 100.0, 9, 'SAN'),
	(10, 250.0, 10, 'MIA');
