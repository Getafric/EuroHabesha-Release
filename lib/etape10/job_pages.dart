import '../l10n/app_ui.dart';

import 'dart:convert';

import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

import 'workspace_ui.dart';

const ehDuration = {
  'hours': 'Quelques heures',
  'days': 'Quelques jours',
  'weeks': 'Une ou plusieurs semaines',
  'months': 'Un ou plusieurs mois',
  'ongoing': 'Durée indéterminée',
};
const ehSalaryMode = {
  'fixed': 'Montant fixe',
  'range': 'Fourchette',
  'discuss': 'À discuter',
};
const ehSalaryUnit = {
  'hour': 'Par heure',
  'day': 'Par jour',
  'month': 'Par mois',
  'mission': 'Pour la mission',
};
String ehSalary(EhData j) => j['salaryMode'] == 'discuss'
    ? 'Rémunération à discuter'
    : '${ehMoney(j['salaryMin'], j['currency'] ?? 'EUR')}${j['salaryMode'] == 'range' ? ' à ${ehMoney(j['salaryMax'], j['currency'] ?? 'EUR')}' : ''} '
          '${j['salaryBasis'] == 'gross' ? 'brut' : 'net'} · ${ehSalaryUnit[j['salaryUnit']]}${j['negotiable'] == true ? ' · Négociable' : ''}';

class EhJobsPage extends StatefulWidget {
  const EhJobsPage({super.key});
  @override
  State<EhJobsPage> createState() => _EhJobsPageState();
}

class _EhJobsPageState extends State<EhJobsPage> {
  String _query = '';
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Emplois et renforts',
    actions: [
      IconButton(
        tooltip: 'Mes candidatures',
        icon: const Icon(Icons.assignment_ind),
        onPressed: () => ehOpen<void>(context, const EhMyApplications()),
      ),
      IconButton(
        tooltip: 'Publier ou gérer une offre',
        icon: const Icon(Icons.add_business),
        onPressed: () => ehOpen<void>(context, const EhEmployerPicker()),
      ),
    ],
    body: EhLoad(
      load: () => ehCall('jobs'),
      builder: (d, refresh) {
        final rows = ehRows(d['items'])
            .where(
              (j) => '${j['title']} ${j['city']} ${j['skills']}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
            )
            .toList();
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            ehNote(
              'Renfort de quelques heures ou emploi durable. L’employeur choisit les candidats et les paie directement.',
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Poste, ville ou compétence',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            if (rows.isEmpty)
              ehNote('Aucune offre correspondant à cette recherche.'),
            for (final j in rows)
              ehTile(
                '${j['title']}',
                '${j['employerName']} · ${j['city']}\n${ehSalary(j)}',
                () => ehOpen<void>(context, EhJobDetail(job: j)),
              ),
          ],
        );
      },
    ),
  );
}

class EhEmployerPicker extends StatefulWidget {
  const EhEmployerPicker({super.key});
  @override
  State<EhEmployerPicker> createState() => _EhEmployerPickerState();
}

class _EhEmployerPickerState extends State<EhEmployerPicker> {
  bool _admin = false;
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Choisir l’employeur',
    body: EhLoad(
      key: ValueKey(_admin),
      load: () => ehCall(_admin ? 'businesses.admin' : 'businesses.mine'),
      builder: (d, refresh) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          ehNote(
            'Votre activité déjà publiée est réutilisée. Pour une publication par Euro Habesha, le véritable employeur reste indiqué.',
          ),
          if (d['manager'] == true)
            SwitchListTile(
              title: const AppText('Publier pour un employeur — gestionnaire'),
              value: _admin,
              onChanged: (v) => setState(() => _admin = v),
            ),
          if (ehRows(d['items']).isEmpty)
            ehNote(
              'Aucune activité publiée disponible. Terminez d’abord sa création et sa validation.',
            ),
          for (final b in ehRows(d['items']))
            ehTile(
              '${b['name']}',
              '${b['sourceCollection']}',
              () => ehOpen<void>(context, EhEmployerJobs(source: b)),
            ),
          if (d['manager'] == true)
            ehButton(
              'Gérer un accès emploi limité',
              () => ehOpen<bool>(
                context,
                EhForm(
                  title: 'Accès emploi',
                  note: 'Réservé au propriétaire Euro Habesha. L’UID est visible dans Firebase Authentication. Cet accès donne uniquement la gestion des offres et des candidatures, pas les paiements.',
                  fields: const [
                    EhField('uid', 'UID Firebase du collaborateur', max: 128),
                    EhField(
                      'active',
                      'Activer la gestion des emplois',
                      toggle: true,
                    ),
                  ],
                  save: (v) async {
                    await ehCall('role.grant', v);
                  },
                ),
              ),
              icon: Icons.admin_panel_settings,
            ),
        ],
      ),
    ),
  );
}

Future<void> ehEditJob(
  BuildContext context,
  EhData source, [
  EhData initial = const {},
]) async {
  final id = initial['id'] ?? ehId();
  final initialValues = {
    ...initial,
    'salaryMinEuros': initial['salaryMin'] == null
        ? ''
        : ((initial['salaryMin'] as num) / 100).toStringAsFixed(2),
    'salaryMaxEuros': initial['salaryMax'] == null
        ? ''
        : ((initial['salaryMax'] as num) / 100).toStringAsFixed(2),
    'people': initial['people'] ?? 1,
  };
  await ehOpen<bool>(
    context,
    EhForm(
      title: 'Je cherche du personnel',
      submit: 'Publier l’offre',
      initial: initialValues,
      note:
          'Employeur : ${source['name'] ?? initial['employerName'] ?? 'activité sélectionnée'}. '
          'La durée du besoin et le contrat sont deux informations distinctes. Aucun paiement au candidat ne passe par ce formulaire.',
      fields: const [
        EhField('title', 'Poste recherché', max: 120),
        EhField('city', 'Ville / lieu de travail'),
        EhField('description', 'Travail demandé et horaires précis', lines: 5),
        EhField(
          'skills',
          'Compétences recherchées',
          lines: 3,
          max: 1000,
          required: false,
        ),
        EhField('people', 'Nombre de personnes', number: true),
        EhField('durationKind', 'Durée du besoin', choices: ehDuration),
        EhField('contract', 'Contrat / cadre proposé (CDD, CDI, autre)'),
        EhField('startsAt', 'Date et heure de début', date: true),
        EhField(
          'endsAt',
          'Fin (facultative si durée indéterminée)',
          date: true,
          required: false,
        ),
        EhField('deadline', 'Date limite de candidature', date: true),
        EhField('currency', 'Devise', choices: ehCurrencies),
        EhField('salaryMode', 'Rémunération', choices: ehSalaryMode),
        EhField(
          'salaryMinEuros',
          'Montant fixe ou minimum (devise choisie)',
          number: true,
          required: false,
        ),
        EhField(
          'salaryMaxEuros',
          'Maximum de la fourchette (devise choisie)',
          number: true,
          required: false,
        ),
        EhField('salaryUnit', 'Base du montant', choices: ehSalaryUnit),
        EhField(
          'salaryBasis',
          'Brut / net',
          choices: {'gross': 'Brut', 'net': 'Net'},
        ),
        EhField('negotiable', 'Montant négociable', toggle: true),
        EhField('paymentMethod', 'Mode de paiement prévu'),
        EhField('paymentWhen', 'Quand le paiement est-il prévu ?'),
        EhField(
          'paymentDetails',
          'Précisions de rémunération',
          lines: 3,
          required: false,
          max: 1000,
        ),
      ],
      save: (v) async {
        String iso(String key) =>
            DateTime.parse('${v[key]}').toUtc().toIso8601String();
        await ehCall('job.save', {
          ...source,
          ...v,
          'id': id,
          'startsAt': iso('startsAt'),
          'endsAt': '${v['endsAt']}'.isEmpty ? null : iso('endsAt'),
          'deadline': iso('deadline'),
          'people': int.tryParse('${v['people']}') ?? 0,
          'salaryMin': v['salaryMode'] == 'discuss'
              ? null
              : ehCents(v['salaryMinEuros']),
          'salaryMax': v['salaryMode'] == 'range'
              ? ehCents(v['salaryMaxEuros'])
              : null,
        });
      },
    ),
  );
}

class EhEmployerJobs extends StatelessWidget {
  const EhEmployerJobs({super.key, required this.source});
  final EhData source;
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Recruter pour mon activité',
    body: EhLoad(
      load: () => ehCall('jobs.manage', source),
      builder: (d, refresh) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          ehButton('Publier une offre / un besoin de renfort', () async {
            await ehEditJob(context, source);
            refresh();
          }, icon: Icons.add),
          for (final j in ehRows(d['items']))
            Card(
              color: ehCard,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ehTile(
                      '${j['title']}',
                      '${j['status'] == 'published' ? 'Publiée' : 'Clôturée'} · ${ehSalary(j)}',
                      null,
                    ),
                    ehButton(
                      'Consulter les candidatures',
                      () => ehOpen<void>(context, EhApplications(job: j)),
                      icon: Icons.people,
                    ),
                    ehButton('Modifier l’offre', () async {
                      await ehEditJob(context, source, j);
                      refresh();
                    }, icon: Icons.edit),
                    if (j['status'] == 'published')
                      TextButton(
                        onPressed: () => ehRun(context, () async {
                          await ehCall('job.close', {'id': j['id']});
                          refresh();
                        }),
                        child: const AppText('Clôturer les candidatures'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class EhJobDetail extends StatelessWidget {
  const EhJobDetail({super.key, required this.job});
  final EhData job;
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: '${job['title']}',
    body: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        AppText(
          '${job['employerName']}',
          style: const TextStyle(color: ehGold, fontSize: 24),
        ),
        if (job['postedByPlatform'] == true)
          ehNote('Publiée par Euro Habesha pour cet employeur.'),
        ehNote(
          '${job['city']} · ${ehDuration[job['durationKind']]} · ${job['people']} personne(s)',
        ),
        ehNote('Contrat / cadre : ${job['contract']}'),
        ehNote('Début : ${DateTime.parse(job['startsAt']).toLocal()}'),
        if (job['endsAt'] != null)
          ehNote('Fin : ${DateTime.parse(job['endsAt']).toLocal()}'),
        ehNote('${job['description']}'),
        ehNote('Compétences : ${job['skills']}'),
        ehNote(ehSalary(job)),
        ehNote(
          'Paiement : ${job['paymentMethod']} · ${job['paymentWhen']}\n${job['paymentDetails']}',
        ),
        ehNote(
          'Candidater avant le ${DateTime.parse(job['deadline']).toLocal()}',
        ),
        ehButton(
          'Envoyer ma candidature',
          () => ehOpen<bool>(
            context,
            EhForm(
              title: 'Ma candidature',
              pdfKey: 'cv',
              submit: 'Envoyer à l’employeur',
              note:
                  'Vos coordonnées et votre candidature seront partagées uniquement avec cet employeur et les gestionnaires autorisés. '
                  'Le choix et le paiement sont faits par l’employeur.',
              fields: const [
                EhField('name', 'Nom du candidat', max: 100),
                EhField('city', 'Ville', max: 120),
                EhField(
                  'phone',
                  'Téléphone (facultatif)',
                  required: false,
                  max: 50,
                ),
                EhField(
                  'skills',
                  'Compétences séparées par des virgules',
                  required: false,
                ),
                EhField(
                  'message',
                  'Motivation, expérience et disponibilités',
                  lines: 6,
                ),
                EhField(
                  'consent',
                  'J’accepte de partager ma candidature avec cet employeur',
                  toggle: true,
                ),
              ],
              save: (v) async {
                await ehCall('job.apply', {
                  ...v,
                  'id': job['id'],
                  'skills': ehSplit(v['skills']),
                });
              },
            ),
          ),
          icon: Icons.send,
        ),
      ],
    ),
  );
}

class EhApplications extends StatelessWidget {
  const EhApplications({super.key, required this.job});
  final EhData job;
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Candidatures reçues',
    body: EhLoad(
      load: () => ehCall('job.applications', {'id': job['id']}),
      builder: (d, refresh) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          ehNote(
            'Aucun recrutement automatique. Comparez les compétences et disponibilités déclarées, puis contactez le candidat.',
          ),
          if (ehRows(d['items']).isEmpty)
            ehNote('Aucune candidature pour le moment.'),
          for (final a in ehRows(d['items']))
            Card(
              color: ehCard,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      '${a['name']}',
                      style: const TextStyle(color: ehGold, fontSize: 20),
                    ),
                    ehNote('${a['city']} · ${a['email']} · ${a['phone']}'),
                    ehInterests(a['skills'] as List? ?? []),
                    ehNote('${a['message']}'),
                    if (a['hasCv'] == true)
                      ehButton(
                        'Ouvrir le CV privé',
                        () => ehRun(context, () async {
                          final cv = await ehCall('job.cv', {
                            'id': job['id'],
                            'uid': a['uid'],
                          });
                          if (context.mounted)
                            await ehOpen<void>(
                              context,
                              EhScaffold(
                                title: 'CV privé',
                                body: PdfPreview(
                                  build: (_) async =>
                                      base64Decode(cv['base64']),
                                  allowPrinting: false,
                                  allowSharing: false,
                                ),
                              ),
                            );
                        }),
                        icon: Icons.description,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class EhMyApplications extends StatelessWidget {
  const EhMyApplications({super.key});
  @override
  Widget build(BuildContext context) => EhScaffold(
    title: 'Mes candidatures',
    body: EhLoad(
      load: () => ehCall('applications.mine'),
      builder: (d, refresh) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (ehRows(d['items']).isEmpty)
            ehNote('Vous n’avez pas encore candidaté.'),
          for (final a in ehRows(d['items']))
            ehTile(
              '${a['jobTitle'] ?? 'Candidature envoyée'}',
              '${a['employerName'] ?? ''}\n${a['message']}',
              null,
            ),
        ],
      ),
    ),
  );
}
