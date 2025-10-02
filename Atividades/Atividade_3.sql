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

CREATE OR REPLACE realizar_auditoria()
RETURNS TRIGGER AS $$
BEGIN
	-- Código que será executado
    -- NEW: representa o novo registro (INSERT/UPDATE)
    -- OLD: representa o registro antigo (UPDATE/DELETE)
    
    RETURN NEW; -- ou OLD, ou NULL
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auditoria
	AFTER UPDATE OF idh_educacao, idh_longevidade, idh_geral
	ON indice
	FOR EACH ROW
	EXECUTE FUNCTION realizar_auditoria();
