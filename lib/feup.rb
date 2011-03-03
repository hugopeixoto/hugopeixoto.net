module FEUPHelper
  def student_url code
    "https://www.fe.up.pt/si_uk/ALUNOS_GERAL.FORMVIEW?P_COD=#{code}"
  end

  def staff_url code
    "http://www.fe.up.pt/si_uk/FUNCIONARIOS_GERAL.FORMVIEW?P_CODIGO=#{code}" 
  end
end

Webby::Helpers.register FEUPHelper
