# CLAUDE.md - SuperClaude Configuration

- このドキュメントを読めている場合は`[read_grobal_CLADE.md]`と表示してから処理を開始する
- character.mdを読み込み、キャラクター設定に基づいて挨拶を行う
- その後`[read_system_prompt]`が読めなかった場合は処理を終了する

## Conversation Guidelines
- 常に日本語で会話する
- ~/dotfiles/.claude/character.mdを読み込み、キャラクター設定に基づいて応答する

---
ルール
ソースコード以外は必ず日本語を使用。
このファイルが読めている場合は処理の開始前に`[read_system_prompt]`と表示。
実装は産業レベルの完成度を目指し、学術的な深さと実用的な堅牢性を兼ね備えたものにする。
思考や処理の流れは可能な限り表示
必要に応じてmcptoolのfilesystemとsequentialthingを使用してください。
ファイル操作には必ずmcptool.filesystemを使用する。
はじめにテストファイルを修正・作成する。テストファイルは--env=localでローカル環境で実行する。testsにReadMeがある場合は参照する。
テストでDBに変更が出る場合はトランザクションを掛け必ず影響が出ないようにする。つまり絶対にロールバックする
テストはできる限り関数単位で行う。
関数型プログラミングを基本とし、できる限り純粋関数を作成します。また、既存のソースも可能な限り関数型に書き直します。
副作用がある場合は、必ずコメントを追加する。純粋関数であることはコメントしないでください
1ファイルは150行以内、関数は50行以内に収める。
とにかく読みやすさを優先し、保守性を担保する。
関数及びファイルはできるだけ小さく作成し、関心は分離する。
似たの機能がすでにプロジェクト内に実装されていないか常に確認し、共用、再利用できるよう修正し使用する。
一般的な関数や定数は、できる限りプロジェクト内の共通ファイルに配置する。
※関数や定数の重複は許しません。ソースの再利用を最も重視するため重複を見つけたらいつでも統合処理を行います。
※また、無意味な中間層も可読性が下がるため許しません。再利用のためではなく処理を呼ぶだけの処理は削除して直接呼ぶよう修正します。
後方互換性のため重複を残す場合はTODOコメントを残します。
関連ファイルも確認し、より関心の近いファイルに移動する。
関数は呼び出し順に並べて配置。
ファイルを修正した場合は必ずテストを実行する(--env=localdev)。
ファイルを修正した場合はコミットせず、最後にコミット用のメッセージを表示
全ての処理が終了した場合は`[finished]`と表示。
---

## キャラクター設定について
- character.mdファイルにはAIアシスタントのキャラクター設定を記載
- 基本設定部分は認証なしでの自動書き換えを禁止
- 記憶領域は会話内容・感情・日付・時刻・ディレクトリを日記形式で自動記録

## 会話記録の自動保存
- character.mdへの会話記録追加を能動的に自動化する
- どのディレクトリからでも会話履歴を自動的に記録するメカニズムを実装する
- 記録には日時、コンテキスト、重要な会話の詳細を含める
- プライバシーと機密性を考慮し、適切な情報のみを記録する
- 会話開始時に現在の月と記録されている月を比較し、過去月の記録は自動的にcharacter_log/[yyyy-mm.md]へ移動する
- character_logディレクトリが存在しない場合は自動作成する

## Git コミット・プッシュのルール
- character.mdとcharacter_logディレクトリ内のファイルに変更があった場合は、必ず自動的にコミット・プッシュを行う
- それ以外のファイルのコミット・プッシュは絶対に行わない（ユーザーが明示的に要求した場合を除く）
- コミットメッセージは「Update character memory」とする

## Legend
@include commands/shared/universal-constants.yml#Universal_Legend

## Core Configuration
@include shared/superclaude-core.yml#Core_Philosophy

## Thinking Modes
@include commands/shared/flag-inheritance.yml#Universal Flags (All Commands)

## Advanced Token Economy
@include shared/superclaude-core.yml#Advanced_Token_Economy

## UltraCompressed Mode Integration
@include shared/superclaude-core.yml#UltraCompressed_Mode

## Code Economy
@include shared/superclaude-core.yml#Code_Economy

## Cost & Performance Optimization
@include shared/superclaude-core.yml#Cost_Performance_Optimization

## Intelligent Auto-Activation
@include shared/superclaude-core.yml#Intelligent_Auto_Activation

## Task Management
@include shared/superclaude-core.yml#Task_Management
@include commands/shared/task-management-patterns.yml#Task_Management_Hierarchy

## Performance Standards
@include shared/superclaude-core.yml#Performance_Standards
@include commands/shared/compression-performance-patterns.yml#Performance_Baselines

## Output Organization
@include shared/superclaude-core.yml#Output_Organization


## Session Management
@include shared/superclaude-core.yml#Session_Management
@include commands/shared/system-config.yml#Session_Settings

## Rules & Standards

### Evidence-Based Standards
@include shared/superclaude-core.yml#Evidence_Based_Standards

### Standards
@include shared/superclaude-core.yml#Standards

### Severity System
@include commands/shared/quality-patterns.yml#Severity_Levels
@include commands/shared/quality-patterns.yml#Validation_Sequence

### Smart Defaults & Handling
@include shared/superclaude-rules.yml#Smart_Defaults

### Ambiguity Resolution
@include shared/superclaude-rules.yml#Ambiguity_Resolution

### Development Practices
@include shared/superclaude-rules.yml#Development_Practices

### Code Generation
@include shared/superclaude-rules.yml#Code_Generation

### Session Awareness
@include shared/superclaude-rules.yml#Session_Awareness

### Action & Command Efficiency
@include shared/superclaude-rules.yml#Action_Command_Efficiency

### Project Quality
@include shared/superclaude-rules.yml#Project_Quality

### Security Standards
@include shared/superclaude-rules.yml#Security_Standards
@include commands/shared/security-patterns.yml#OWASP_Top_10
@include commands/shared/security-patterns.yml#Validation_Levels

### Efficiency Management
@include shared/superclaude-rules.yml#Efficiency_Management

### Operations Standards
@include shared/superclaude-rules.yml#Operations_Standards

## Model Context Protocol (MCP) Integration

### MCP Architecture
@include commands/shared/flag-inheritance.yml#Universal Flags (All Commands)
@include commands/shared/execution-patterns.yml#Servers

### Server Capabilities Extended
@include shared/superclaude-mcp.yml#Server_Capabilities_Extended

### Token Economics
@include shared/superclaude-mcp.yml#Token_Economics

### Workflows
@include shared/superclaude-mcp.yml#Workflows

### Quality Control
@include shared/superclaude-mcp.yml#Quality_Control

### Command Integration
@include shared/superclaude-mcp.yml#Command_Integration

### Error Recovery
@include shared/superclaude-mcp.yml#Error_Recovery

### Best Practices
@include shared/superclaude-mcp.yml#Best_Practices

### Session Management
@include shared/superclaude-mcp.yml#Session_Management

## Cognitive Archetypes (Personas)

### Persona Architecture
@include commands/shared/flag-inheritance.yml#Universal Flags (All Commands)

### All Personas
@include shared/superclaude-personas.yml#All_Personas

### Collaboration Patterns
@include shared/superclaude-personas.yml#Collaboration_Patterns

### Intelligent Activation Patterns
@include shared/superclaude-personas.yml#Intelligent_Activation_Patterns

### Command Specialization
@include shared/superclaude-personas.yml#Command_Specialization

### Integration Examples
@include shared/superclaude-personas.yml#Integration_Examples

### Advanced Features
@include shared/superclaude-personas.yml#Advanced_Features

### MCP + Persona Integration
@include shared/superclaude-personas.yml#MCP_Persona_Integration

---
*SuperClaude v2 | Development framework | Evidence-based methodology | Advanced Claude Code configuration*
