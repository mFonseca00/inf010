-- CONSULTAS NA BASE DE DADOS ACADEMICOS:
----------------------------------------------------------
-- OPÇÕES DEFINIDAS PARA REALIZAR CONSULTAS:
----------------------------------------------------------
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
-- CONSULTAS COM ANÁLISE DE PERFORMANCE:
--------------------------------------------------------------------

-- CONSULTA 1: Departamentos, Professores, Turmas e Média (2006-2010)

-- Consulta Original (SEM otimização)
EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE)
SELECT
    d.dept_name AS departamento,
    i.name AS professor,
    c.title AS disciplina,
    sec.sec_id AS turma,
    sec.semester AS semestre,
    sec.year AS ano,
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
GROUP BY d.dept_name, i.name, c.title, sec.sec_id, sec.semester, sec.year
ORDER BY d.dept_name, ano, semestre, c.title;

-- Intervenção: Criar índices para otimizar a consulta
CREATE INDEX IF NOT EXISTS idx_section_year ON section(year);
CREATE INDEX IF NOT EXISTS idx_section_composite ON section(course_id, sec_id, semester, year);
CREATE INDEX IF NOT EXISTS idx_teaches_composite ON teaches(course_id, sec_id, semester, year);
CREATE INDEX IF NOT EXISTS idx_takes_composite ON takes(course_id, sec_id, semester, year);
CREATE INDEX IF NOT EXISTS idx_instructor_dept ON instructor(dept_name);

-- Consulta Otimizada (COM índices)
EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE)
SELECT
    d.dept_name AS departamento,
    i.name AS professor,
    c.title AS disciplina,
    sec.sec_id AS turma,
    sec.semester AS semestre,
    sec.year AS ano,
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
GROUP BY d.dept_name, i.name, c.title, sec.sec_id, sec.semester, sec.year
ORDER BY d.dept_name, ano, semestre, c.title;

/*
ANÁLISE DA CONSULTA 1:
- Comparar os planos de execução (ANTES e DEPOIS)
- Verificar se houve mudança de Seq Scan para Index Scan
- Observar redução no tempo de execução (Execution Time)
- Analisar uso de buffers (Buffers: shared hit/read)
- Comentar se a intervenção foi efetiva ou não
*/

--------------------------------------------------------------------

-- CONSULTA 2: Alunos, Disciplinas, Professores, Notas e Departamentos

-- Consulta Original (SEM otimização)
EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE)
SELECT
    s.name AS aluno,
    c.title AS disciplina,
    i.name AS professor,
    d.dept_name AS departamento,
    v.semester AS semestre,
    v.year AS ano,
    v.grade AS nota_letra,
    v.nota_numerica
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
WHERE v.nota_numerica IS NOT NULL
ORDER BY s.name, ano, semestre, c.title;

-- Intervenção: Criar índices adicionais para otimizar a consulta
CREATE INDEX IF NOT EXISTS idx_student_id ON student(ID);
CREATE INDEX IF NOT EXISTS idx_takes_id ON takes(ID);
CREATE INDEX IF NOT EXISTS idx_teaches_id ON teaches(ID);
CREATE INDEX IF NOT EXISTS idx_course_id ON course(course_id);

-- Consulta Otimizada (COM índices)
EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE)
SELECT
    s.name AS aluno,
    c.title AS disciplina,
    i.name AS professor,
    d.dept_name AS departamento,
    v.semester AS semestre,
    v.year AS ano,
    v.grade AS nota_letra,
    v.nota_numerica
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
WHERE v.nota_numerica IS NOT NULL
ORDER BY s.name, ano, semestre, c.title;

/*
ANÁLISE DA CONSULTA 2:
- Comparar os planos de execução (ANTES e DEPOIS)
- Verificar se houve mudança de Seq Scan para Index Scan
- Observar redução no tempo de execução (Execution Time)
- Analisar uso de buffers (Buffers: shared hit/read)
- Comentar se a intervenção foi efetiva ou não
*/