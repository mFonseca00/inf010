-- V2 da função que calcula idx, atualizando e retornando o valor do idx para um registro específico 
-- (tivemos que refazer, pois a versão anterior não contemplava retornar o valor, fazendo o cálculo para toda a tabela de uma vez)
CREATE OR REPLACE FUNCTION
CalcularIdx(p_cod_municipio DECIMAL, p_ano DECIMAL, p_idh_educacao DECIMAL, p_idh_longevidade DECIMAL, p_idh_geral DECIMAL)
RETURNS DECIMAL(8,3)
AS $$
DECLARE
    novo_idx DECIMAL(8,3);
BEGIN
    novo_idx := (((p_idh_educacao * p_idh_educacao) * p_idh_longevidade) / p_idh_geral);
    
    UPDATE indice
    SET idx = novo_idx
    WHERE codmunicipio = p_cod_municipio AND ano = p_ano;
    
    RETURN novo_idx;
END;
$$ LANGUAGE plpgsql;

-- Criação da tabela de auditoria
CREATE TABLE AUDITORIA(
	id SERIAL,
	data DATE NOT NULL,
	valor_antigo_idx DECIMAL(8,3) NOT NULL,
	novo_valor_idx DECIMAL(8,3) NOT NULL,
	diferenca DECIMAL(8,3) NOT NULL,
	cod_municipio DECIMAL NOT NULL,
	ano INTEGER NOT NULL,
	CONSTRAINT pk_id PRIMARY KEY (id),
	CONSTRAINT fk_municipio FOREIGN KEY (cod_municipio) REFERENCES Municipio (CodMunicipio)
)

-- Função chamada pelo gatilho
CREATE OR REPLACE FUNCTION realizar_auditoria()
RETURNS TRIGGER AS $$
DECLARE
    old_idx_value DECIMAL(8,3);
    new_idx_value DECIMAL(8,3);
BEGIN
    old_idx_value := OLD.idx;
    
    new_idx_value := CalcularIdx(NEW.codmunicipio, NEW.ano, NEW.idh_educacao, NEW.idh_longevidade, NEW.idh_geral);
    
    NEW.idx := new_idx_value;
    
    INSERT INTO AUDITORIA(data, valor_antigo_idx, novo_valor_idx, diferenca, cod_municipio, ano)
        VALUES (CURRENT_DATE, old_idx_value, new_idx_value, (new_idx_value - old_idx_value), NEW.codmunicipio, NEW.ano);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Definição do gatilho
CREATE TRIGGER trigger_auditoria
	BEFORE UPDATE OF idh_educacao, idh_longevidade, idh_geral
	ON indice
	FOR EACH ROW
	EXECUTE FUNCTION realizar_auditoria();

-- Função para retornar a média das diferenças de IDX do dia
CREATE OR REPLACE FUNCTION media_diferencas_dia_atual()
RETURNS DECIMAL(10,3) AS $$
DECLARE
    media_resultado DECIMAL(10,3);
BEGIN
    SELECT AVG(ABS(diferenca))
    INTO media_resultado
    FROM AUDITORIA
    WHERE data = CURRENT_DATE;

    RETURN COALESCE(media_resultado, 0);
END;
$$ LANGUAGE plpgsql;

-- teste
UPDATE indice
SET idh_educacao = idh_educacao + 0.04
WHERE codmunicipio = 354880 AND ano = 1991;

UPDATE indice
SET idh_longevidade = idh_longevidade + 0.35
WHERE codmunicipio = 350060 AND ano = 1991;

UPDATE indice
SET idh_geral = idh_geral - 0.98
WHERE codmunicipio = 330330 AND ano = 1991;

SELECT media_diferencas_dia_atual();