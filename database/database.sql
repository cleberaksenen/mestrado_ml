CREATE DATABASE doadores_ml;

USE doadores_ml;

CREATE TABLE paciente (
    paciente_id INTEGER PRIMARY KEY AUTO_INCREMENT,
    redcap_id INTEGER,
    tipo_paciente TEXT,
    identificador_pesfis INTEGER,
    dt_nascimento DATE,
    idade_anos INT,
    genero ENUM("MASCULINO", "FEMININO"),
    grupo_abo ENUM("A", "B", "AB", "O", "NAO INFORMADO"),
    antigeno_abo ENUM("Rh+", "Rh-", "NAO INFORMADO"),
    escolaridade ENUM("NAO ALFABETIZADO", "FUNDAMENTAL I", "FUNDAMENTAL II", "ENSINO MEDIO INCOMPLETO", "ENSINO MEDIO COMPLETO", "TERCEIRO GRAU INCOMPLETO", "TERCEIRO GRAU COMPLETO", "POS GRADUADO", "ESPECIALIZADO", "MESTRADO", "DOUTORADO", "NAO INFORMADO"),
    escolaridade_group TEXT
    etnia ENUM("PARDA", "AMARELA", "BRANCA", "PRETA", "INDIGENA", "NAO INFORMADO"),
    altura_m NUMERIC(4,2),
    municipio TEXT,
    bairro TEXT,
    regional TEXT,
    peso NUMERIC(5,2),
    pulso INTEGER,
    temperatura_celsius NUMERIC(4,2),
    pressao_min INTEGER,
    pressao_max INTEGER,
    hemoglobina NUMERIC(4,2),
    vacina_covid19 TEXT,
    dt_dose01 DATE,
    dt_dose02 DATE,
    dt_dose03 DATE,
    dt_dose04 DATE,
    fabricante_dose01 ENUM('PFIZER (12 ANOS OU MAIS)', 'ASTRAZENECA', 'CORONAVAC', 'JANSSEN', 'NAO INFORMADO'),
    fabricante_dose02 ENUM('PFIZER (12 ANOS OU MAIS)', 'ASTRAZENECA', 'CORONAVAC', 'JANSSEN', 'NAO INFORMADO'),
    fabricante_dose03 ENUM('PFIZER (12 ANOS OU MAIS)', 'ASTRAZENECA', 'CORONAVAC', 'JANSSEN', 'NAO INFORMADO'),
    fabricante_dose04 ENUM('PFIZER (12 ANOS OU MAIS)', 'ASTRAZENECA', 'CORONAVAC', 'JANSSEN', 'NAO INFORMADO')
);

CREATE TABLE exame (
    exame_id INT PRIMARY KEY AUTO_INCREMENT,
    paciente_id INT,
    identificador_doacao TEXT,
    quantitativo_igg FLOAT,
    dt_coleta_amostra DATE,
    dt_coleta_bolsa DATE,
    dt_definitiva_amostra DATE,
    dt_ultima_vacina DATE,
    tipo_ensaio ENUM('Anti-N', 'Anti-S'),
    dt_ultima_vacina DATE,
    num_doses INT,
    FOREIGN KEY (paciente_id) REFERENCES paciente(paciente_id)
);

-------------------------------------------------------
--- Alterações ---

UPDATE exame e
JOIN paciente p ON e.paciente_id = p.paciente_id
SET e.dt_ultima_vacina = (
    SELECT MAX(d)
    FROM (
        SELECT p.dt_dose01 AS d
        UNION ALL
        SELECT p.dt_dose02
        UNION ALL
        SELECT p.dt_dose03
        UNION ALL
        SELECT p.dt_dose04
    ) AS doses
    WHERE d IS NOT NULL AND d <= e.dt_definitiva_amostra
);

UPDATE exame e
JOIN paciente p ON e.paciente_id = p.paciente_id
SET e.num_doses =
    (CASE WHEN p.dt_dose01 <= e.dt_definitiva_amostra THEN 1 ELSE 0 END) +
    (CASE WHEN p.dt_dose02 <= e.dt_definitiva_amostra THEN 1 ELSE 0 END) +
    (CASE WHEN p.dt_dose03 <= e.dt_definitiva_amostra THEN 1 ELSE 0 END) +
    (CASE WHEN p.dt_dose04 <= e.dt_definitiva_amostra THEN 1 ELSE 0 END);

UPDATE paciente
SET escolaridade_group = CASE
    WHEN escolaridade IN ('POS GRADUADO', 'ESPECIALIZADO', 'MESTRADO', 'DOUTORADO', 'TERCEIRO GRAU COMPLETO') THEN 'TERCEIRO GRAU COMPLETO'
    WHEN escolaridade IN ('TERCEIRO GRAU INCOMPLETO', 'ENSINO MEDIO COMPLETO') THEN 'ENSINO MEDIO COMPLETO'
    WHEN escolaridade IN ('FUNDAMENTAL I', 'FUNDAMENTAL II', 'NAO ALFABETIZADO') THEN 'ENSINO MEDIO INCOMPLETO'
    ELSE 'NAO INFORMADO'
END;

UPDATE paciente p
JOIN exame e ON p.paciente_id = e.paciente_id
SET p.idade_anos = TIMESTAMPDIFF(YEAR, p.dt_nascimento, e.dt_definitiva_amostra);