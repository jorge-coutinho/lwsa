require_relative "../lib/order"

# Exemplos do comportamento esperado. Estão `pending` para o esqueleto rodar verde de
# início — conforme implementar, remova os `pending`, ajuste à sua API e adicione os seus
# (caminho feliz, criação inválida, transição inválida, retry até failed, estado final).
RSpec.describe Order do
  let(:order) { described_class.new(domain: "loja.exemplo.com.br", provider: "lets_encrypt") }

  it "começa em pending com 0 tentativas" do
    # pending("implemente o initialize")
    expect(order.status).to eq("pending")
    expect(order.validation_attempts).to eq(0)
  end

  it "segue o caminho feliz até installed" do
    # pending("implemente o apply")
    order.apply(:start_validation)
    order.apply(:validate_ok)
    order.apply(:install)
    expect(order.status).to eq("installed")
  end

  it "recusa transição inválida sem mudar o estado" do
    # pending("implemente o tratamento de transição inválida")
    expect { order.apply(:install) }.to raise_error(Order::InvalidTransition)
    expect(order.status).to eq("pending")
  end

  it "vai para failed ao atingir MAX_VALIDATION_ATTEMPTS" do
    # pending("implemente o retry da validação")
    order.apply(:start_validation)
    order.apply(:validate_fail)
    order.apply(:validate_fail)
    order.apply(:validate_fail)
    expect(order.status).to eq("failed")
  end

  describe "criação inválida" do
    it "recusa domain inválido" do
      expect { Order.new(domain: "semtld", provider: "lets_encrypt") }.to raise_error(ArgumentError)
    end

    it "recusa domain vazio" do
      expect { Order.new(domain: "", provider: "lets_encrypt") }.to raise_error(ArgumentError)
    end

    it "recusa provider desconhecido" do
      expect { Order.new(domain: "exemplo.com", provider: "comodo") }.to raise_error(ArgumentError)
    end
  end

  describe "cancel" do
    it "vai para failed a partir de pending" do
      order.apply(:cancel)
      expect(order.status).to eq("failed")
    end

    it "vai para failed a partir de validating" do
      order.apply(:start_validation)
      order.apply(:cancel)
      expect(order.status).to eq("failed")
    end

    it "vai para failed a partir de issued" do
      order.apply(:start_validation)
      order.apply(:validate_ok)
      order.apply(:cancel)
      expect(order.status).to eq("failed")
    end
  end

  describe "estados finais" do
    it "installed não aceita nenhum evento" do
      order.apply(:start_validation)
      order.apply(:validate_ok)
      order.apply(:install)

      %i[start_validation validate_ok validate_fail install cancel].each do |event|
        expect { order.apply(event) }.to raise_error(Order::InvalidTransition)
      end
    end

    it "failed não aceita nenhum evento" do
      order.apply(:cancel)

      %i[start_validation validate_ok validate_fail install cancel].each do |event|
        expect { order.apply(event) }.to raise_error(Order::InvalidTransition)
      end
    end

    it "final? retorna true para installed e failed" do
      expect(order.final?).to be false
      order.apply(:cancel)
      expect(order.final?).to be true
    end
  end

  describe "retry de validação" do
    before { order.apply(:start_validation) }

    it "permanece validating e incrementa tentativas" do
      order.apply(:validate_fail)
      expect(order.status).to eq("validating")
      expect(order.validation_attempts).to eq(1)
    end

    it "pode recuperar com validate_ok antes do limite" do
      order.apply(:validate_fail)
      order.apply(:validate_fail)
      order.apply(:validate_ok)
      expect(order.status).to eq("issued")
    end

    it "falha após o limite de tentativas" do
      order.apply(:validate_fail)
      order.apply(:validate_fail)
      order.apply(:validate_fail)
      expect(order.status).to eq("failed")
    end
  end
end
