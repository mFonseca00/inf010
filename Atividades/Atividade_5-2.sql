-- CONSULTAS NA BASE DE DADOS ACADEMICOS:

-- OPÇÕES DEFINIDAS PARA REALIZAR CONSULTAS:

-- OPÇÃO 1: VIEW COM CASE
CREATE VIEW v_notas_numericas AS
SELECT 
    ID, course_id, sec_id, semester, year, grade,
    CASE grade
        WHEN 'A+' THEN 4.3
        WHEN 'A ' THEN 4.0
        WHEN 'A-' THEN 3.7
        WHEN 'B+' THEN 3.3
        WHEN 'B ' THEN 3.0
        WHEN 'B-' THEN 2.7
        WHEN 'C+' THEN 2.3
        WHEN 'C ' THEN 2.0
        WHEN 'C-' THEN 1.7
        WHEN 'D+' THEN 1.3
        WHEN 'D ' THEN 1.0
        WHEN 'D-' THEN 0.7
        WHEN 'F ' THEN 0.0
        ELSE NULL
    END AS nota_numerica
FROM takes;

-- OPÇÃO 2: FUNCTION
CREATE OR REPLACE FUNCTION converter_nota(grade_letra VARCHAR(2))
RETURNS NUMERIC(3,2) AS $$
BEGIN
    RETURN CASE grade_letra
        WHEN 'A+' THEN 4.3
        WHEN 'A ' THEN 4.0
        WHEN 'A-' THEN 3.7
        WHEN 'B+' THEN 3.3
        WHEN 'B ' THEN 3.0
        WHEN 'B-' THEN 2.7
        WHEN 'C+' THEN 2.3
        WHEN 'C ' THEN 2.0
        WHEN 'C-' THEN 1.7
        WHEN 'D+' THEN 1.3
        WHEN 'D ' THEN 1.0
        WHEN 'D-' THEN 0.7
        WHEN 'F ' THEN 0.0
        ELSE NULL
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- OPÇÃO 3: TABELA DE CONVERSÃO
CREATE TABLE escala_notas (
    grade VARCHAR(2) PRIMARY KEY,
    valor_numerico NUMERIC(3,2) NOT NULL
);

INSERT INTO escala_notas VALUES
    ('A+', 4.3), ('A ', 4.0), ('A-', 3.7),
    ('B+', 3.3), ('B ', 3.0), ('B-', 2.7),
    ('C+', 2.3), ('C ', 2.0), ('C-', 1.7),
    ('D+', 1.3), ('D ', 1.0), ('D-', 0.7),
    ('F ', 0.0);
CREATE INDEX idx_escala_grade ON escala_notas(grade);

--------------------------------------------------------------------
-- CONSULTAS:
--------------------------------------------------------------------

-- Tabela para resultados
DROP TABLE IF EXISTS benchmark_resultados;
CREATE TABLE benchmark_resultados (
    id SERIAL PRIMARY KEY,
    consulta VARCHAR(200),
    opcao VARCHAR(50),
    tempo_ms NUMERIC(10,2),
    timestamp TIMESTAMP DEFAULT NOW()
);

-- CONSULTA 1: Departamentos, Professores, Turmas e Média (2006-2010)

-- Opção 1: VIEW
DO $$
DECLARE
    inicio TIMESTAMP;
    tempo_ms NUMERIC;
BEGIN
    inicio := clock_timestamp();
    
    PERFORM
        d.dept_name, i.name, c.title, sec.sec_id, sec.semester, sec.year,
        COUNT(v.ID) AS total_alunos,
        ROUND(AVG(v.nota_numerica), 2) AS media_notas,
        ROUND(MIN(v.nota_numerica), 2) AS nota_minima,
        ROUND(MAX(v.nota_numerica), 2) AS nota_maxima
    FROM department d
    INNER JOIN instructor i ON d.dept_name = i.dept_name
    INNER JOIN teaches t ON i.ID = t.ID
    INNER JOIN section sec ON t.course_id = sec.course_id 
        AND t.sec_id = sec.sec_id 
        AND t.semester = sec.semester 
        AND t.year = sec.year
    INNER JOIN course c ON sec.course_id = c.course_id
    INNER JOIN v_notas_numericas v ON sec.course_id = v.course_id 
        AND sec.sec_id = v.sec_id 
        AND sec.semester = v.semester 
        AND sec.year = v.year
    WHERE sec.year BETWEEN 2006 AND 2010 AND v.nota_numerica IS NOT NULL
    GROUP BY d.dept_name, i.name, c.title, sec.sec_id, sec.semester, sec.year;
    
    tempo_ms := EXTRACT(EPOCH FROM (clock_timestamp() - inicio)) * 1000;
    INSERT INTO benchmark_resultados VALUES (DEFAULT, 'Consulta 1', 'VIEW', tempo_ms, DEFAULT);
END $$;

-- Opção 2: FUNCTION
DO $$
DECLARE
    inicio TIMESTAMP;
    tempo_ms NUMERIC;
BEGIN
    inicio := clock_timestamp();
    
    PERFORM
        d.dept_name, i.name, c.title, sec.sec_id, sec.semester, sec.year,
        COUNT(tk.ID) AS total_alunos,
        ROUND(AVG(converter_nota(tk.grade)), 2) AS media_notas,
        ROUND(MIN(converter_nota(tk.grade)), 2) AS nota_minima,
        ROUND(MAX(converter_nota(tk.grade)), 2) AS nota_maxima
    FROM department d
    INNER JOIN instructor i ON d.dept_name = i.dept_name
    INNER JOIN teaches t ON i.ID = t.ID
    INNER JOIN section sec ON t.course_id = sec.course_id 
        AND t.sec_id = sec.sec_id 
        AND t.semester = sec.semester 
        AND t.year = sec.year
    INNER JOIN course c ON sec.course_id = c.course_id
    INNER JOIN takes tk ON sec.course_id = tk.course_id 
        AND sec.sec_id = tk.sec_id 
        AND sec.semester = tk.semester 
        AND sec.year = tk.year
    WHERE sec.year BETWEEN 2006 AND 2010 AND tk.grade IS NOT NULL
    GROUP BY d.dept_name, i.name, c.title, sec.sec_id, sec.semester, sec.year;
    
    tempo_ms := EXTRACT(EPOCH FROM (clock_timestamp() - inicio)) * 1000;
    INSERT INTO benchmark_resultados VALUES (DEFAULT, 'Consulta 1', 'FUNCTION', tempo_ms, DEFAULT);
END $$;

-- Opção 3: JOIN
DO $$
DECLARE
    inicio TIMESTAMP;
    tempo_ms NUMERIC;
BEGIN
    inicio := clock_timestamp();
    
    PERFORM
        d.dept_name, i.name, c.title, sec.sec_id, sec.semester, sec.year,
        COUNT(tk.ID) AS total_alunos,
        ROUND(AVG(en.valor_numerico), 2) AS media_notas,
        ROUND(MIN(en.valor_numerico), 2) AS nota_minima,
        ROUND(MAX(en.valor_numerico), 2) AS nota_maxima
    FROM department d
    INNER JOIN instructor i ON d.dept_name = i.dept_name
    INNER JOIN teaches t ON i.ID = t.ID
    INNER JOIN section sec ON t.course_id = sec.course_id 
        AND t.sec_id = sec.sec_id 
        AND t.semester = sec.semester 
        AND t.year = sec.year
    INNER JOIN course c ON sec.course_id = c.course_id
    INNER JOIN takes tk ON sec.course_id = tk.course_id 
        AND sec.sec_id = tk.sec_id 
        AND sec.semester = tk.semester 
        AND sec.year = tk.year
    LEFT JOIN escala_notas en ON tk.grade = en.grade
    WHERE sec.year BETWEEN 2006 AND 2010 AND en.valor_numerico IS NOT NULL
    GROUP BY d.dept_name, i.name, c.title, sec.sec_id, sec.semester, sec.year;
    
    tempo_ms := EXTRACT(EPOCH FROM (clock_timestamp() - inicio)) * 1000;
    INSERT INTO benchmark_resultados VALUES (DEFAULT, 'Consulta 1', 'JOIN', tempo_ms, DEFAULT);
END $$;

-- CONSULTA 2: Alunos, Disciplinas, Professores, Notas e Departamentos

-- Opção 1: VIEW
DO $$
DECLARE
    inicio TIMESTAMP;
    tempo_ms NUMERIC;
BEGIN
    inicio := clock_timestamp();
    
    PERFORM
        s.name, c.title, i.name, d.dept_name, v.semester, v.year, 
        v.grade, v.nota_numerica
    FROM student s
    INNER JOIN v_notas_numericas v ON s.ID = v.ID
    INNER JOIN course c ON v.course_id = c.course_id
    INNER JOIN section sec ON v.course_id = sec.course_id 
        AND v.sec_id = sec.sec_id 
        AND v.semester = sec.semester 
        AND v.year = sec.year
    INNER JOIN teaches t ON sec.course_id = t.course_id 
        AND sec.sec_id = t.sec_id 
        AND sec.semester = t.semester 
        AND sec.year = t.year
    INNER JOIN instructor i ON t.ID = i.ID
    INNER JOIN department d ON i.dept_name = d.dept_name
    WHERE v.nota_numerica IS NOT NULL;
    
    tempo_ms := EXTRACT(EPOCH FROM (clock_timestamp() - inicio)) * 1000;
    INSERT INTO benchmark_resultados VALUES (DEFAULT, 'Consulta 2', 'VIEW', tempo_ms, DEFAULT);
END $$;

-- Opção 2: FUNCTION
DO $$
DECLARE
    inicio TIMESTAMP;
    tempo_ms NUMERIC;
BEGIN
    inicio := clock_timestamp();
    
    PERFORM
        s.name, c.title, i.name, d.dept_name, tk.semester, tk.year,
        tk.grade, converter_nota(tk.grade) AS nota_numerica
    FROM student s
    INNER JOIN takes tk ON s.ID = tk.ID
    INNER JOIN course c ON tk.course_id = c.course_id
    INNER JOIN section sec ON tk.course_id = sec.course_id 
        AND tk.sec_id = sec.sec_id 
        AND tk.semester = sec.semester 
        AND tk.year = sec.year
    INNER JOIN teaches t ON sec.course_id = t.course_id 
        AND sec.sec_id = t.sec_id 
        AND sec.semester = t.semester 
        AND sec.year = t.year
    INNER JOIN instructor i ON t.ID = i.ID
    INNER JOIN department d ON i.dept_name = d.dept_name
    WHERE tk.grade IS NOT NULL;
    
    tempo_ms := EXTRACT(EPOCH FROM (clock_timestamp() - inicio)) * 1000;
    INSERT INTO benchmark_resultados VALUES (DEFAULT, 'Consulta 2', 'FUNCTION', tempo_ms, DEFAULT);
END $$;

-- Opção 3: JOIN
DO $$
DECLARE
    inicio TIMESTAMP;
    tempo_ms NUMERIC;
BEGIN
    inicio := clock_timestamp();
    
    PERFORM
        s.name, c.title, i.name, d.dept_name, tk.semester, tk.year,
        tk.grade, en.valor_numerico AS nota_numerica
    FROM student s
    INNER JOIN takes tk ON s.ID = tk.ID
    INNER JOIN course c ON tk.course_id = c.course_id
    INNER JOIN section sec ON tk.course_id = sec.course_id 
        AND tk.sec_id = sec.sec_id 
        AND tk.semester = sec.semester 
        AND tk.year = sec.year
    INNER JOIN teaches t ON sec.course_id = t.course_id 
        AND sec.sec_id = t.sec_id 
        AND sec.semester = t.semester 
        AND sec.year = t.year
    INNER JOIN instructor i ON t.ID = i.ID
    INNER JOIN department d ON i.dept_name = d.dept_name
    LEFT JOIN escala_notas en ON tk.grade = en.grade
    WHERE en.valor_numerico IS NOT NULL;
    
    tempo_ms := EXTRACT(EPOCH FROM (clock_timestamp() - inicio)) * 1000;
    INSERT INTO benchmark_resultados VALUES (DEFAULT, 'Consulta 2', 'JOIN', tempo_ms, DEFAULT);
END $$;

-- Resultados
SELECT 
    consulta, opcao, ROUND(tempo_ms, 2) AS tempo_ms,
    RANK() OVER (PARTITION BY consulta ORDER BY tempo_ms) AS ranking
FROM benchmark_resultados
ORDER BY consulta, ranking;

-- Resumo
SELECT 
    opcao, ROUND(AVG(tempo_ms), 2) AS tempo_medio_ms,
    RANK() OVER (ORDER BY AVG(tempo_ms)) AS ranking_geral
FROM benchmark_resultados
GROUP BY opcao
ORDER BY ranking_geral;