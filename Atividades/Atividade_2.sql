CREATE VIEW vw_passageiros_arrecadacao AS
SELECT 
    l.id AS linha_id,
    l.nome AS linha_nome,
    DATE(vp.data_hora) AS data_viagem,
    COUNT(vp.id) AS qtd_passageiros,
    SUM(vp.valor_pago) AS arrecadacao_total
FROM VendaPassagem vp
JOIN Viagem v ON vp.viagem_id = v.id
JOIN Linha l ON v.linha_id = l.id
GROUP BY l.id, l.nome, DATE(vp.data_hora)
ORDER BY data_viagem, l.nome;