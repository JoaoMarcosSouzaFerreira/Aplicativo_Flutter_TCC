// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'broker.dart';
import 'dadosexperimento.dart';
import 'experimento.dart';
import 'experimento_data_service.dart';
import 'custom_page_route.dart'; // NOVO: Importando a rota de transição

class IntegrantesScreen extends StatefulWidget {
  const IntegrantesScreen({super.key});

  @override
  State<IntegrantesScreen> createState() => _IntegrantesScreenState();
}

class _IntegrantesScreenState extends State<IntegrantesScreen> {
  // A lógica interna do State permanece a mesma
  final ServicoDadosExperimento _servicoDados = ServicoDadosExperimento();
  List<TextEditingController> _controladoresNome = [];
  List<TextEditingController> _controladoresMatricula = [];
  int _contagemAtualMembros = 1;
  final TextEditingController _controladorDia = TextEditingController();
  final TextEditingController _controladorMes = TextEditingController();
  final TextEditingController _controladorAno = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _podeDarPopNaTela = true;

  @override
  void initState() {
    super.initState();
    _inicializarControladoresECarregarDados();
    _servicoDados.definirCallbackAoMudarDados(_lidarComMudancaDeDados);
    _podeDarPopNaTela = !_servicoDados.possuiAlteracoesNaoSalvas;
    _controladorDia.addListener(() => _servicoDados.atualizarData(dia: _controladorDia.text));
    _controladorMes.addListener(() => _servicoDados.atualizarData(mes: _controladorMes.text));
    _controladorAno.addListener(() => _servicoDados.atualizarData(ano: _controladorAno.text));
  }

  @override
  void dispose() {
    for (var ctrl in _controladoresNome) { ctrl.dispose(); }
    for (var ctrl in _controladoresMatricula) { ctrl.dispose(); }
    _controladorDia.dispose();
    _controladorMes.dispose();
    _controladorAno.dispose();
    _servicoDados.definirCallbackAoMudarDados(null);
    super.dispose();
  }

  void _inicializarControladoresECarregarDados() {
    for (var ctrl in _controladoresNome) { ctrl.removeListener(() {}); ctrl.dispose(); }
    for (var ctrl in _controladoresMatricula) { ctrl.removeListener(() {}); ctrl.dispose(); }
    _controladoresNome = [];
    _controladoresMatricula = [];
    for (int i = 0; i < _servicoDados.membros.length; i++) {
      final ctrlNome = TextEditingController(text: _servicoDados.membros[i].nome);
      final ctrlMatricula = TextEditingController(text: _servicoDados.membros[i].matricula);
      final indiceAtual = i;
      ctrlNome.addListener(() { if (indiceAtual < _servicoDados.membros.length) { _servicoDados.atualizarMembro(indiceAtual, nome: ctrlNome.text); } });
      ctrlMatricula.addListener(() { if (indiceAtual < _servicoDados.membros.length) { _servicoDados.atualizarMembro(indiceAtual, matricula: ctrlMatricula.text); } });
      _controladoresNome.add(ctrlNome);
      _controladoresMatricula.add(ctrlMatricula);
    }
    _controladorDia.text = _servicoDados.dataDoExperimento.dia;
    _controladorMes.text = _servicoDados.dataDoExperimento.mes;
    _controladorAno.text = _servicoDados.dataDoExperimento.ano;
    if (mounted) {
      setState(() {
        _contagemAtualMembros = _servicoDados.membros.length;
        _podeDarPopNaTela = !_servicoDados.possuiAlteracoesNaoSalvas;
      });
    }
  }

  void _lidarComMudancaDeDados() {
    if (_contagemAtualMembros != _servicoDados.membros.length || _controladoresNome.length != _servicoDados.membros.length) {
      _inicializarControladoresECarregarDados();
    } else if (mounted) {
      setState(() { _podeDarPopNaTela = !_servicoDados.possuiAlteracoesNaoSalvas; });
    }
  }

  void _adicionarNovoMembro() { _servicoDados.adicionarMembro(); }

  void _removerMembroSelecionado(int indice) {
    if (_servicoDados.membros.length > 1) {
      _servicoDados.removerMembro(indice);
    } else {
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: const Text('Deve haver pelo menos um integrante.'), backgroundColor: Theme.of(context).colorScheme.error),);
    }
  }

  void _salvarDadosNaLogicaLocal() {
    _servicoDados.salvarDados();
    ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: const Text('Dados salvos com sucesso!'), backgroundColor: Theme.of(context).colorScheme.secondary),);
  }

  void _iniciarFluxoDoExperimento() {
    final todosNomesPreenchidos = _servicoDados.membros.every((m) => m.nome.trim().isNotEmpty);
    final todasMatriculasPreenchidas = _servicoDados.membros.every((m) => m.matricula.trim().isNotEmpty);
    final dataPreenchida = _servicoDados.dataDoExperimento.dia.trim().isNotEmpty && _servicoDados.dataDoExperimento.mes.trim().isNotEmpty && _servicoDados.dataDoExperimento.ano.trim().isNotEmpty;

    if (todosNomesPreenchidos && todasMatriculasPreenchidas && dataPreenchida) {
      if (_servicoDados.possuiAlteracoesNaoSalvas) {
        showDialog( context: context, builder: (contextoDialogo) => AlertDialog( title: const Text('Salvar Alterações?'), content: const Text( 'Você tem alterações não salvas. Deseja salvá-las antes de prosseguir para o Broker?'), actions: [ TextButton( onPressed: () { Navigator.pop(contextoDialogo); Navigator.push(context, FadePageRoute(child: const ConectaBroker())); }, child: const Text('Continuar sem Salvar'), ), ElevatedButton( onPressed: () { _salvarDadosNaLogicaLocal(); Navigator.pop(contextoDialogo); Navigator.push(context, FadePageRoute(child: const ConectaBroker())); }, child: const Text('Salvar e Continuar'), ), ], ),
        );
      } else {
        Navigator.push(context, FadePageRoute(child: const ConectaBroker())); // NOVO: Usando FadePageRoute
      }
      return;
    }
    String textoAlerta;
    if (!dataPreenchida && (!todosNomesPreenchidos || !todasMatriculasPreenchidas)) { textoAlerta = 'Você não preencheu nem os dados dos integrantes nem a data.\nO relatório será gerado sem essas informações.'; } else if (!dataPreenchida) { textoAlerta = 'Você não informou a data do experimento.\nO relatório será gerado sem data.'; } else { textoAlerta = 'Você não preencheu os dados dos integrantes.\nO relatório será gerado sem identificação dos membros.'; }
    showDialog( context: context, builder: (contextoDialogo) => AlertDialog( title: const Text('Campos não preenchidos'), content: Column( mainAxisSize: MainAxisSize.min, children: [ SizedBox( width: 100, height: 100, child: LottieBuilder.asset('assets/Alerta.json', fit: BoxFit.contain), ), const SizedBox(height: 16), Text(textoAlerta, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)), ], ), actionsAlignment: MainAxisAlignment.center, actions: [ TextButton( onPressed: () => Navigator.pop(contextoDialogo), child: const Text('Preencher dados'), ), ElevatedButton( onPressed: () { Navigator.pop(contextoDialogo); Navigator.push(context, FadePageRoute(child: const ConectaBroker())); }, child: const Text('Ir para Broker'), ), ], ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 24.0),
      child: Text( title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_controladoresNome.length != _servicoDados.membros.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) { _inicializarControladoresECarregarDados(); } });
    }
    return PopScope(
      canPop: _podeDarPopNaTela,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final resultado = await showDialog<String>( context: context, barrierDismissible: false, builder: (contextoDialogo) => AlertDialog( title: const Text('Alterações Não Salvas'), content: const Text('Você tem alterações não salvas. Deseja salvá-las antes de sair desta tela?'), actions: [ TextButton(onPressed: () => Navigator.pop(contextoDialogo, 'descartar_e_sair'), child: const Text('Descartar e Sair'), ), ElevatedButton(onPressed: () { Navigator.pop(contextoDialogo, 'salvar_e_sair'); }, child: const Text('Salvar e Sair'), ), ], ),
        );
        if (mounted) {
          if (resultado == 'salvar_e_sair') {
            _salvarDadosNaLogicaLocal();
            setState(() => _podeDarPopNaTela = true);
            WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.pop(context); });
          } else if (resultado == 'descartar_e_sair') {
            setState(() => _podeDarPopNaTela = true);
            WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.pop(context); });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar( automaticallyImplyLeading: false, title: const Text('Dados dos Integrantes'), ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Integrantes do Grupo', context),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _contagemAtualMembros,
                        itemBuilder: (contextoItem, i) {
                          if (i >= _controladoresNome.length) { _controladoresNome.add(TextEditingController()); }
                          if (i >= _controladoresMatricula.length) { _controladoresMatricula.add(TextEditingController()); }
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row( children: [ Icon(Icons.person_outline, color: theme.colorScheme.primary), const SizedBox(width: 8), Text('Integrante ${i + 1}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const Spacer(), if (_contagemAtualMembros > 1) IconButton(onPressed: () => _removerMembroSelecionado(i), icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error), tooltip: 'Remover Integrante',), ], ),
                                  const SizedBox(height: 16),
                                  TextFormField( key: ValueKey('nome_${_servicoDados.membros[i].id}'), controller: _controladoresNome[i], decoration: const InputDecoration(labelText: 'Nome Completo'), textCapitalization: TextCapitalization.words, ),
                                  const SizedBox(height: 12),
                                  TextFormField( key: ValueKey('matricula_${_servicoDados.membros[i].id}'), controller: _controladoresMatricula[i], decoration: const InputDecoration(labelText: 'Matrícula'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (_contagemAtualMembros < 4) Padding( padding: const EdgeInsets.symmetric(vertical: 16.0), child: Center( child: TextButton.icon( onPressed: _adicionarNovoMembro, icon: const Icon(Icons.add_circle_outline), label: const Text('Adicionar Integrante'), style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary,),),),),
                      _buildSectionTitle('Data do Experimento', context),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded( child: TextFormField( controller: _controladorDia, decoration: const InputDecoration(labelText: 'Dia', prefixIcon: Icon(Icons.calendar_today_outlined)), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)], textAlign: TextAlign.center,),),
                              const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text("/", style: TextStyle(fontSize: 24))),
                              Expanded( child: TextFormField(controller: _controladorMes, decoration: const InputDecoration(labelText: 'Mês'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)], textAlign: TextAlign.center,)),
                              const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0), child: Text("/", style: TextStyle(fontSize: 24))),
                              Expanded( flex: 2, child: TextFormField( controller: _controladorAno, decoration: const InputDecoration(labelText: 'Ano'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], textAlign: TextAlign.center,)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration( color: theme.colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))], borderRadius: const BorderRadius.only( topLeft: Radius.circular(20), topRight: Radius.circular(20),)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon( onPressed: _servicoDados.possuiAlteracoesNaoSalvas ? _salvarDadosNaLogicaLocal : null, icon: const Icon(Icons.save_alt_outlined), label: const Text('Salvar Alterações'), style: OutlinedButton.styleFrom( minimumSize: const Size(double.infinity, 50), foregroundColor: theme.colorScheme.primary, side: BorderSide(color: _servicoDados.possuiAlteracoesNaoSalvas ? theme.colorScheme.primary : Colors.grey.shade400,)),),
                    const SizedBox(height: 10),
                    ElevatedButton.icon( onPressed: _iniciarFluxoDoExperimento, icon: const Icon(Icons.cloud_upload_outlined), label: const Text('Inserir Dados do Broker'), style: ElevatedButton.styleFrom( backgroundColor: theme.colorScheme.secondary, foregroundColor: theme.colorScheme.onSecondary,),), // ESTILO: Botão de sucesso usa a cor secundária (verde)
                  ],
                )),
          ],
        ),
        bottomNavigationBar: _construirBarraNavegacaoInferior(),
      ),
    );
  }

  Widget _construirBarraNavegacaoInferior() {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0: break;
          case 1: _verificarAlteracoesAntesDeNavegarParaOutraTela(() { Navigator.pushReplacement(context, FadePageRoute(child: const ConectaBroker())); }); break; // NOVO: Usando FadePageRoute
          case 2: _verificarAlteracoesAntesDeNavegarParaOutraTela(() { Navigator.pushReplacement(context, FadePageRoute(child: const DadosExperimentos())); }); break; // NOVO: Usando FadePageRoute
          case 3: _verificarAlteracoesAntesDeNavegarParaOutraTela(() { Navigator.pushReplacement(context, FadePageRoute(child: const Experimento())); }); break; // NOVO: Usando FadePageRoute
        }
      },
      destinations: const [
        NavigationDestination( selectedIcon: Icon(Icons.group), icon: Icon(Icons.group_outlined), label: 'Integrantes',),
        NavigationDestination( selectedIcon: Icon(Icons.cloud), icon: Icon(Icons.cloud_outlined), label: 'Broker',),
        NavigationDestination( selectedIcon: Icon(Icons.assignment), icon: Icon(Icons.assignment_outlined), label: 'Dados Exp.',),
        NavigationDestination( selectedIcon: Icon(Icons.science), icon: Icon(Icons.science_outlined), label: 'Experimento',),
      ],
    );
  }

  void _verificarAlteracoesAntesDeNavegarParaOutraTela(VoidCallback acaoNavegar) async {
    if (_servicoDados.possuiAlteracoesNaoSalvas) {
      final resultado = await showDialog<String>( context: context, barrierDismissible: false, builder: (contextoDialogo) => AlertDialog( title: const Text('Alterações Não Salvas'), content: const Text('Você tem alterações não salvas. Deseja descartá-las antes de prosseguir?'), actions: [ TextButton( onPressed: () => Navigator.pop(contextoDialogo, 'descartar'), child: const Text('Descartar e Prosseguir'), ), ElevatedButton( onPressed: () { Navigator.pop(contextoDialogo, 'salvar'); }, child: const Text('Salvar e Prosseguir'), ), ], ),
      );
      if (resultado == 'salvar') {
        _salvarDadosNaLogicaLocal();
        WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) acaoNavegar(); });
      } else if (resultado == 'descartar') {
        acaoNavegar();
      }
    } else {
      acaoNavegar();
    }
  }
}