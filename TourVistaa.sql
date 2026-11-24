CREATE DATABASE IF NOT EXISTS plataforma_viagens
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE plataforma_viagens;

-- ============================================================================
-- 1. ENTIDADES ESSENCIAIS DO MVP
-- ============================================================================

-- 1.1. Utilizador
CREATE TABLE Utilizador (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    tipo_utilizador VARCHAR(20) NOT NULL DEFAULT 'VIAJANTE',
    data_registo TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado_conta VARCHAR(50) DEFAULT 'ativo',
    CONSTRAINT chk_utilizador_tipo CHECK (tipo_utilizador IN ('VIAJANTE', 'ADMINISTRADOR')),
    CONSTRAINT chk_utilizador_estado CHECK (estado_conta IN ('ativo', 'inativo', 'suspenso'))
);

-- 1.5. Tipo_Viajante (criada antes de Perfil_Utilizador e Roteiro por causa da FK)
CREATE TABLE Tipo_Viajante (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT NULL
);

-- 1.2. Perfil_Utilizador
CREATE TABLE Perfil_Utilizador (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilizador_id INT NOT NULL UNIQUE,
    tipo_viajante_id INT NULL,
    faixa_orcamento VARCHAR(50) NULL,
    ritmo VARCHAR(50) NULL,
    lingua_preferida VARCHAR(10) DEFAULT 'pt-PT',
    CONSTRAINT fk_perfil_utilizador FOREIGN KEY (utilizador_id) REFERENCES Utilizador(id),
    CONSTRAINT fk_perfil_tipo_viajante FOREIGN KEY (tipo_viajante_id) REFERENCES Tipo_Viajante(id)
);

-- 1.4. Categoria (criada antes de Utilizador_Categoria, Atracao_Categoria e Guia_Viagem)
CREATE TABLE Categoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT NULL,
    icone VARCHAR(100) NULL,
    gratuito_por_defeito BOOLEAN NOT NULL DEFAULT FALSE
);

-- 1.3. Utilizador_Categoria (Associação N:N)
CREATE TABLE Utilizador_Categoria (
    utilizador_id INT NOT NULL,
    categoria_id INT NOT NULL,
    PRIMARY KEY (utilizador_id, categoria_id),
    CONSTRAINT fk_uc_utilizador FOREIGN KEY (utilizador_id) REFERENCES Utilizador(id),
    CONSTRAINT fk_uc_categoria FOREIGN KEY (categoria_id) REFERENCES Categoria(id)
);

-- 1.6. Pais
CREATE TABLE Pais (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    codigo_iso VARCHAR(3) NOT NULL UNIQUE
);

-- 1.7. Regiao
CREATE TABLE Regiao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pais_id INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    CONSTRAINT fk_regiao_pais FOREIGN KEY (pais_id) REFERENCES Pais(id)
);

-- 1.8. Localidade
CREATE TABLE Localidade (
    id INT AUTO_INCREMENT PRIMARY KEY,
    regiao_id INT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    codigo_postal VARCHAR(20) NULL,
    latitude DECIMAL(10,8) NULL,
    longitude DECIMAL(11,8) NULL,
    CONSTRAINT fk_localidade_regiao FOREIGN KEY (regiao_id) REFERENCES Regiao(id)
);

-- 1.9. Atracao
CREATE TABLE Atracao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    localidade_id INT NOT NULL,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    morada VARCHAR(255) NULL,
    custo_medio DECIMAL(10,2) NULL,
    requer_reserva BOOLEAN NOT NULL DEFAULT FALSE,
    link_externo TEXT NULL,
    origem VARCHAR(20) NOT NULL DEFAULT 'API',
    estado VARCHAR(20) NOT NULL DEFAULT 'PUBLICADO',
    submetido_por_id INT NULL,
    proprietario_id INT NULL,
    classificacao_media DECIMAL(3,2) NULL,
    total_avaliacoes INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_atracao_localidade FOREIGN KEY (localidade_id) REFERENCES Localidade(id),
    CONSTRAINT fk_atracao_submetido_por FOREIGN KEY (submetido_por_id) REFERENCES Utilizador(id),
    CONSTRAINT fk_atracao_proprietario FOREIGN KEY (proprietario_id) REFERENCES Utilizador(id),
    CONSTRAINT chk_atracao_origem CHECK (origem IN ('API', 'COMUNIDADE')),
    CONSTRAINT chk_atracao_estado CHECK (estado IN ('PENDENTE', 'PUBLICADO', 'REJEITADO'))
);

-- 1.10. Atracao_Categoria (Associação N:N)
CREATE TABLE Atracao_Categoria (
    atracao_id INT NOT NULL,
    categoria_id INT NOT NULL,
    PRIMARY KEY (atracao_id, categoria_id),
    CONSTRAINT fk_ac_atracao FOREIGN KEY (atracao_id) REFERENCES Atracao(id),
    CONSTRAINT fk_ac_categoria FOREIGN KEY (categoria_id) REFERENCES Categoria(id)
);

-- 1.11. Imagem_Atracao
CREATE TABLE Imagem_Atracao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    atracao_id INT NOT NULL,
    url_imagem TEXT NOT NULL,
    ordem INT NULL,
    principal BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_imagem_atracao FOREIGN KEY (atracao_id) REFERENCES Atracao(id)
);

-- 1.12. Horario_Atracao
CREATE TABLE Horario_Atracao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    atracao_id INT NOT NULL,
    dia_semana TINYINT NULL,
    hora_abertura TIME NULL,
    hora_fecho TIME NULL,
    CONSTRAINT fk_horario_atracao FOREIGN KEY (atracao_id) REFERENCES Atracao(id),
    CONSTRAINT chk_horario_dia_semana CHECK (dia_semana IS NULL OR (dia_semana BETWEEN 0 AND 6))
);

-- 1.13. Favorito
CREATE TABLE Favorito (
    utilizador_id INT NOT NULL,
    atracao_id INT NOT NULL,
    data_adicao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (utilizador_id, atracao_id),
    CONSTRAINT fk_favorito_utilizador FOREIGN KEY (utilizador_id) REFERENCES Utilizador(id),
    CONSTRAINT fk_favorito_atracao FOREIGN KEY (atracao_id) REFERENCES Atracao(id)
);

-- 1.14. Roteiro
CREATE TABLE Roteiro (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilizador_id INT NOT NULL,
    tipo_viajante_id INT NULL,
    titulo VARCHAR(200) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    usa_carro BOOLEAN NOT NULL DEFAULT FALSE,
    com_estimativa BOOLEAN NOT NULL DEFAULT FALSE,
    orcamento_inicial DECIMAL(10,2) NULL,
    custo_transporte_estimado DECIMAL(10,2) DEFAULT 0.00,
    moeda_orcamento VARCHAR(3) DEFAULT 'EUR',
    estado VARCHAR(50) DEFAULT 'Rascunho',
    CONSTRAINT fk_roteiro_utilizador FOREIGN KEY (utilizador_id) REFERENCES Utilizador(id),
    CONSTRAINT fk_roteiro_tipo_viajante FOREIGN KEY (tipo_viajante_id) REFERENCES Tipo_Viajante(id),
    CONSTRAINT chk_roteiro_estado CHECK (estado IN ('Rascunho', 'Confirmado', 'Concluído'))
);

-- 1.15. Roteiro_Destino (Associação N:N com ordenação)
CREATE TABLE Roteiro_Destino (
    roteiro_id INT NOT NULL,
    localidade_id INT NOT NULL,
    ordem_destino INT NOT NULL,
    PRIMARY KEY (roteiro_id, ordem_destino),
    CONSTRAINT fk_rd_roteiro FOREIGN KEY (roteiro_id) REFERENCES Roteiro(id),
    CONSTRAINT fk_rd_localidade FOREIGN KEY (localidade_id) REFERENCES Localidade(id)
);

-- 1.16. Dia_Roteiro
CREATE TABLE Dia_Roteiro (
    id INT AUTO_INCREMENT PRIMARY KEY,
    roteiro_id INT NOT NULL,
    numero_dia INT NOT NULL,
    data DATE NULL,
    CONSTRAINT fk_dia_roteiro FOREIGN KEY (roteiro_id) REFERENCES Roteiro(id)
);

-- 1.17. Item_Roteiro
CREATE TABLE Item_Roteiro (
    id INT AUTO_INCREMENT PRIMARY KEY,
    dia_roteiro_id INT NOT NULL,
    atracao_id INT NOT NULL,
    ordem_visita INT NOT NULL,
    hora_prevista TIME NULL,
    duracao_estimada_min INT NULL,
    custo_previsto DECIMAL(10,2) NULL,
    reservado BOOLEAN NOT NULL DEFAULT FALSE,
    notas TEXT NULL,
    CONSTRAINT fk_item_dia_roteiro FOREIGN KEY (dia_roteiro_id) REFERENCES Dia_Roteiro(id),
    CONSTRAINT fk_item_atracao FOREIGN KEY (atracao_id) REFERENCES Atracao(id)
);

-- 1.18. Viagem_Realizada
CREATE TABLE Viagem_Realizada (
    id INT AUTO_INCREMENT PRIMARY KEY,
    roteiro_id INT NOT NULL UNIQUE,
    data_efetiva_inicio DATE NOT NULL,
    data_efetiva_fim DATE NOT NULL,
    avaliacao_geral TINYINT NULL,
    comentario_geral TEXT NULL,
    CONSTRAINT fk_viagem_roteiro FOREIGN KEY (roteiro_id) REFERENCES Roteiro(id),
    CONSTRAINT chk_viagem_avaliacao CHECK (avaliacao_geral IS NULL OR (avaliacao_geral BETWEEN 1 AND 5))
);

-- 1.19. Guia_Viagem
CREATE TABLE Guia_Viagem (
    id INT AUTO_INCREMENT PRIMARY KEY,
    localidade_id INT NOT NULL,
    categoria_id INT NULL,
    autor_id INT NULL,
    titulo VARCHAR(200) NOT NULL,
    resumo TEXT NOT NULL,
    conteudo_html TEXT NULL,
    imagem_capa TEXT NULL,
    total_utilizacoes INT NOT NULL DEFAULT 0,
    publicado BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_guia_localidade FOREIGN KEY (localidade_id) REFERENCES Localidade(id),
    CONSTRAINT fk_guia_categoria FOREIGN KEY (categoria_id) REFERENCES Categoria(id),
    CONSTRAINT fk_guia_autor FOREIGN KEY (autor_id) REFERENCES Utilizador(id)
);

-- 1.20. Guia_Atracao (Associação N:N com ordenação)
CREATE TABLE Guia_Atracao (
    guia_viagem_id INT NOT NULL,
    atracao_id INT NOT NULL,
    ordem_visita INT NOT NULL,
    PRIMARY KEY (guia_viagem_id, atracao_id),
    CONSTRAINT fk_ga_guia FOREIGN KEY (guia_viagem_id) REFERENCES Guia_Viagem(id),
    CONSTRAINT fk_ga_atracao FOREIGN KEY (atracao_id) REFERENCES Atracao(id)
);

-- ============================================================================
-- 2. ENTIDADES DE SUPORTE À IMPLEMENTAÇÃO
-- ============================================================================

-- 2.1. Sessao
CREATE TABLE Sessao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilizador_id INT NOT NULL,
    token_acesso TEXT NOT NULL,
    token_renovacao TEXT NULL,
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_expiracao TIMESTAMP NOT NULL,
    ip_address VARCHAR(45) NULL,
    CONSTRAINT fk_sessao_utilizador FOREIGN KEY (utilizador_id) REFERENCES Utilizador(id)
);

-- 2.2. Fonte_Informacao
CREATE TABLE Fonte_Informacao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    api_endpoint TEXT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

-- 2.3. Atracao_Fonte (Associação N:N)
CREATE TABLE Atracao_Fonte (
    atracao_id INT NOT NULL,
    fonte_id INT NOT NULL,
    id_externo VARCHAR(100) NOT NULL,
    atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (atracao_id, fonte_id),
    CONSTRAINT fk_af_atracao FOREIGN KEY (atracao_id) REFERENCES Atracao(id),
    CONSTRAINT fk_af_fonte FOREIGN KEY (fonte_id) REFERENCES Fonte_Informacao(id)
);

-- ============================================================================
-- 3. NICE-TO-HAVE — EVOLUÇÃO FUTURA
-- ============================================================================

-- 3.1. Fornecedor
CREATE TABLE Fornecedor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    ativo BOOLEAN DEFAULT TRUE
);

-- 3.2. Oferta
CREATE TABLE Oferta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    atracao_id INT NOT NULL,
    fornecedor_id INT NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    moeda VARCHAR(3) DEFAULT 'EUR',
    link_externo TEXT NOT NULL,
    atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_oferta_atracao FOREIGN KEY (atracao_id) REFERENCES Atracao(id),
    CONSTRAINT fk_oferta_fornecedor FOREIGN KEY (fornecedor_id) REFERENCES Fornecedor(id)
);

-- 3.3. Avaliacao_Atracao
CREATE TABLE Avaliacao_Atracao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    atracao_id INT NOT NULL,
    utilizador_id INT NOT NULL,
    pontuacao TINYINT NOT NULL,
    comentario TEXT NULL,
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_avaliacao_atracao FOREIGN KEY (atracao_id) REFERENCES Atracao(id),
    CONSTRAINT fk_avaliacao_utilizador FOREIGN KEY (utilizador_id) REFERENCES Utilizador(id),
    CONSTRAINT chk_avaliacao_pontuacao CHECK (pontuacao BETWEEN 1 AND 5)
);

-- 3.4. Sincronizacao_API
CREATE TABLE Sincronizacao_API (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fonte_id INT NOT NULL,
    data_inicio TIMESTAMP NOT NULL,
    data_fim TIMESTAMP NULL,
    estado VARCHAR(50) NOT NULL,
    registos_importados INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_sync_fonte FOREIGN KEY (fonte_id) REFERENCES Fonte_Informacao(id),
    CONSTRAINT chk_sync_estado CHECK (estado IN ('Sucesso', 'Erro', 'Em curso'))
);

-- 3.5. Deslocacao
CREATE TABLE Deslocacao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_origem_id INT NOT NULL,
    item_destino_id INT NOT NULL,
    distancia_km DECIMAL(6,2) NULL,
    tempo_estimado_min INT NULL,
    meio_transporte VARCHAR(50) NULL,
    CONSTRAINT fk_deslocacao_origem FOREIGN KEY (item_origem_id) REFERENCES Item_Roteiro(id),
    CONSTRAINT fk_deslocacao_destino FOREIGN KEY (item_destino_id) REFERENCES Item_Roteiro(id)
);

-- 3.6. Sugestao
CREATE TABLE Sugestao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilizador_id INT NOT NULL,
    roteiro_id INT NULL,
    atracao_id INT NOT NULL,
    tipo_sugestao VARCHAR(100) NOT NULL,
    texto_justificativa TEXT NULL,
    criada_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sugestao_utilizador FOREIGN KEY (utilizador_id) REFERENCES Utilizador(id),
    CONSTRAINT fk_sugestao_roteiro FOREIGN KEY (roteiro_id) REFERENCES Roteiro(id),
    CONSTRAINT fk_sugestao_atracao FOREIGN KEY (atracao_id) REFERENCES Atracao(id)
);