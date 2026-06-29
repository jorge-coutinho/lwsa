# Pedido de certificado SSL (Ruby puro). Implemente a lógica do enunciado.
# Pode reorganizar à vontade (ex.: separar a máquina de estados em outra classe) —
# só explique no README.
#
# Estados: pending, validating, issued, installed (final), failed (final)
# Eventos: start_validation, validate_ok, validate_fail, install, cancel
class Order
  PROVIDERS = %w[lets_encrypt globalsign].freeze
  MAX_VALIDATION_ATTEMPTS = 3
  INITIAL_STATE = "pending"
  FINAL_STATES = %w[installed failed].freeze
  # Levante isto numa transição não permitida (sugestão de nome).
  class InvalidTransition < StandardError; end

  attr_reader :domain, :provider
  attr_accessor :status, :validation_attempts

  # domain: string (formato de domínio válido); provider: um de PROVIDERS.
  # Deve recusar criação com dados inválidos.
  def initialize(domain:, provider:)
    validate!(domain:, provider:)
    @domain = domain
    @provider = provider
    @status = INITIAL_STATE
    @validation_attempts = 0
  end

  # Aplica um evento de transição (ver enunciado) e retorna o novo estado.
  def apply(event)
    validate_transition!(event)
    transition(event)
    status
  end

  # true se o pedido está em um estado final (installed ou failed).
  def final?
    FINAL_STATES.include?(@status)
  end

  private
    def validate_transition!(event)
      raise InvalidTransition, "Evento inválido para o estado atual: #{@status}" unless valid_transition?(event)
    end

    def validate!(domain:, provider:)
      raise ArgumentError, "Domain deve ser um nome de domínio válido" unless valid_domain?(domain)
      raise ArgumentError, "provider deve ser um dos seguintes: #{PROVIDERS.join(', ')}" unless PROVIDERS.include?(provider)
    end

    def valid_domain?(domain)
      domain =~ /\A([a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?\.)+[a-z]{2,}\z/i
    end

    def valid_transition?(event)
      case event
      when :start_validation then status == "pending"
      when :validate_ok      then status == "validating"
      when :validate_fail    then status == "validating"
      when :install          then status == "issued"
      when :cancel           then !final?
      else false
      end
    end

    def transition(event)
      case event
      when :start_validation then @status = "validating"
      when :validate_ok      then @status = "issued"
      when :validate_fail
        @validation_attempts += 1
        @status = "failed" if @validation_attempts >= MAX_VALIDATION_ATTEMPTS
      when :install          then @status = "installed"
      when :cancel           then @status = "failed"
      end
    end
end
