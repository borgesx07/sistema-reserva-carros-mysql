-- =====================================================================
--  Sistema de Reserva de Carros  (baseado no estudo de caso da SQL Magazine 74)
--  Script DDL - somente criação do banco e das tabelas
--  SGBD: MySQL 8 / MariaDB
-- =====================================================================

DROP DATABASE IF EXISTS reserva_carros;
CREATE DATABASE reserva_carros
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE reserva_carros;

-- ---------------------------------------------------------------------
-- Filial / agência onde os carros são retirados e devolvidos
-- ---------------------------------------------------------------------
CREATE TABLE filial (
    id_filial     INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(80)  NOT NULL,
    endereco      VARCHAR(150) NOT NULL,
    cidade        VARCHAR(80)  NOT NULL,
    uf            CHAR(2)      NOT NULL,
    telefone      VARCHAR(20)
);

-- ---------------------------------------------------------------------
-- Categoria (grupo) do carro: define o valor da diária
-- ---------------------------------------------------------------------
CREATE TABLE categoria (
    id_categoria  INT AUTO_INCREMENT PRIMARY KEY,
    descricao     VARCHAR(50)   NOT NULL UNIQUE,   -- ex.: Econômico, Executivo, SUV
    valor_diaria  DECIMAL(10,2) NOT NULL CHECK (valor_diaria > 0)
);

-- ---------------------------------------------------------------------
-- Fabricante e modelo
-- ---------------------------------------------------------------------
CREATE TABLE fabricante (
    id_fabricante INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE modelo (
    id_modelo     INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(50) NOT NULL,
    id_fabricante INT NOT NULL,
    id_categoria  INT NOT NULL,
    CONSTRAINT fk_modelo_fabricante FOREIGN KEY (id_fabricante) REFERENCES fabricante (id_fabricante),
    CONSTRAINT fk_modelo_categoria  FOREIGN KEY (id_categoria)  REFERENCES categoria  (id_categoria)
);

-- ---------------------------------------------------------------------
-- Carro (veículo físico da frota)
-- ---------------------------------------------------------------------
CREATE TABLE carro (
    placa         CHAR(7)     PRIMARY KEY,
    chassi        VARCHAR(17) NOT NULL UNIQUE,
    id_modelo     INT         NOT NULL,
    id_filial     INT         NOT NULL,          -- filial onde o carro está
    ano           SMALLINT    NOT NULL,
    cor           VARCHAR(30),
    quilometragem INT         NOT NULL DEFAULT 0,
    situacao      ENUM('DISPONIVEL','RESERVADO','LOCADO','MANUTENCAO')
                              NOT NULL DEFAULT 'DISPONIVEL',
    CONSTRAINT fk_carro_modelo FOREIGN KEY (id_modelo) REFERENCES modelo (id_modelo),
    CONSTRAINT fk_carro_filial FOREIGN KEY (id_filial) REFERENCES filial (id_filial)
);

-- ---------------------------------------------------------------------
-- Cliente e seus telefones
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL,
    cpf             CHAR(11)     NOT NULL UNIQUE,
    cnh             VARCHAR(11)  NOT NULL UNIQUE,
    validade_cnh    DATE         NOT NULL,
    data_nascimento DATE         NOT NULL,
    email           VARCHAR(100),
    endereco        VARCHAR(150),
    cidade          VARCHAR(80),
    uf              CHAR(2)
);

CREATE TABLE telefone_cliente (
    id_cliente    INT         NOT NULL,
    telefone      VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_cliente, telefone),
    CONSTRAINT fk_telefone_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- Funcionário (atendente que registra reservas/locações)
-- ---------------------------------------------------------------------
CREATE TABLE funcionario (
    id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(100) NOT NULL,
    cpf            CHAR(11)     NOT NULL UNIQUE,
    cargo          VARCHAR(50)  NOT NULL,
    id_filial      INT          NOT NULL,
    CONSTRAINT fk_funcionario_filial FOREIGN KEY (id_filial) REFERENCES filial (id_filial)
);

-- ---------------------------------------------------------------------
-- Reserva: o cliente reserva uma CATEGORIA para um período
-- ---------------------------------------------------------------------
CREATE TABLE reserva (
    id_reserva          INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente          INT      NOT NULL,
    id_categoria        INT      NOT NULL,
    id_funcionario      INT,
    id_filial_retirada  INT      NOT NULL,
    id_filial_devolucao INT      NOT NULL,
    data_reserva        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_retirada       DATETIME NOT NULL,
    data_devolucao      DATETIME NOT NULL,
    valor_previsto      DECIMAL(10,2),
    status              ENUM('ATIVA','CANCELADA','CONCLUIDA')
                                 NOT NULL DEFAULT 'ATIVA',
    CONSTRAINT ck_reserva_datas CHECK (data_devolucao > data_retirada),
    CONSTRAINT fk_reserva_cliente     FOREIGN KEY (id_cliente)          REFERENCES cliente     (id_cliente),
    CONSTRAINT fk_reserva_categoria   FOREIGN KEY (id_categoria)        REFERENCES categoria   (id_categoria),
    CONSTRAINT fk_reserva_funcionario FOREIGN KEY (id_funcionario)      REFERENCES funcionario (id_funcionario),
    CONSTRAINT fk_reserva_fil_ret     FOREIGN KEY (id_filial_retirada)  REFERENCES filial      (id_filial),
    CONSTRAINT fk_reserva_fil_dev     FOREIGN KEY (id_filial_devolucao) REFERENCES filial      (id_filial)
);

-- ---------------------------------------------------------------------
-- Locação: efetivação da reserva com um carro específico
-- ---------------------------------------------------------------------
CREATE TABLE locacao (
    id_locacao         INT AUTO_INCREMENT PRIMARY KEY,
    id_reserva         INT      NOT NULL UNIQUE,     -- 1 reserva gera no máx. 1 locação
    placa              CHAR(7)  NOT NULL,
    id_funcionario     INT      NOT NULL,
    data_hora_retirada DATETIME NOT NULL,
    km_retirada        INT      NOT NULL,
    data_hora_entrega  DATETIME,
    km_entrega         INT,
    valor_total        DECIMAL(10,2),
    CONSTRAINT ck_locacao_km CHECK (km_entrega IS NULL OR km_entrega >= km_retirada),
    CONSTRAINT fk_locacao_reserva     FOREIGN KEY (id_reserva)     REFERENCES reserva     (id_reserva),
    CONSTRAINT fk_locacao_carro       FOREIGN KEY (placa)          REFERENCES carro       (placa),
    CONSTRAINT fk_locacao_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario (id_funcionario)
);

-- ---------------------------------------------------------------------
-- Pagamento da locação
-- ---------------------------------------------------------------------
CREATE TABLE pagamento (
    id_pagamento   INT AUTO_INCREMENT PRIMARY KEY,
    id_locacao     INT           NOT NULL,
    forma          ENUM('DINHEIRO','CARTAO_CREDITO','CARTAO_DEBITO','PIX') NOT NULL,
    valor          DECIMAL(10,2) NOT NULL CHECK (valor > 0),
    data_pagamento DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pagamento_locacao FOREIGN KEY (id_locacao) REFERENCES locacao (id_locacao)
);

-- Índices para consultas frequentes (disponibilidade por período)
CREATE INDEX idx_reserva_periodo ON reserva (data_retirada, data_devolucao);
CREATE INDEX idx_carro_situacao  ON carro   (situacao);

-- Para conferir na apresentação:
-- SHOW TABLES;
-- DESCRIBE reserva;
