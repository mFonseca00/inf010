ALTERALTER TABLE indice
ADD COLUMN idx numeric(8,3);

CREATE OR REPLACE FUNCTION
CalcularIdx()

RETURNS VOID
AS $$
BEGIN
UPDATE indice
SET idx = (((idh_educacao*idh_educacao)*idh_longevidade)/idh_geral);
END;
$$ LANGUAGE plpgsql
