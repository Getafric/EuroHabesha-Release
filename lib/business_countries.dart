/// Country labels: Unicode CLDR (Babel 2.17), ISO alpha-2/alpha-3 names.
/// XK is included as the CLDR Kosovo entry. No network lookup is needed.
class BusinessCountry {
  const BusinessCountry(this.code, this.name, this.aliases);
  final String code;
  final String name;
  final List<String> aliases;
  String get flag =>
      String.fromCharCodes(code.codeUnits.map((c) => c + 127397));
}

class BusinessCountryResolution {
  const BusinessCountryResolution(
    this.country,
    this.source, {
    this.unknownName = '',
  });
  final BusinessCountry? country;
  final String source;
  final String unknownName;
}

class BusinessCountries {
  BusinessCountries._();
  static const List<BusinessCountry> all = [
    BusinessCountry('AF', 'Afghanistan', [
      'AFG',
      'Afghanistan',
      'Islamic Republic of Afghanistan',
    ]),
    BusinessCountry('ZA', 'Afrique du Sud', [
      'Republic of South Africa',
      'South Africa',
      'ZAF',
    ]),
    BusinessCountry('AL', 'Albanie', ['ALB', 'Albania', 'Republic of Albania']),
    BusinessCountry('DZ', 'Algérie', [
      'Algeria',
      'DZA',
      'People\'s Democratic Republic of Algeria',
    ]),
    BusinessCountry('DE', 'Allemagne', [
      'DEU',
      'Deutschland',
      'Federal Republic of Germany',
      'Germany',
    ]),
    BusinessCountry('AD', 'Andorre', [
      'AND',
      'Andorra',
      'Principality of Andorra',
    ]),
    BusinessCountry('AO', 'Angola', ['AGO', 'Angola', 'Republic of Angola']),
    BusinessCountry('AI', 'Anguilla', ['AIA', 'Anguilla']),
    BusinessCountry('AQ', 'Antarctique', ['ATA', 'Antarctica']),
    BusinessCountry('AG', 'Antigua-et-Barbuda', [
      'ATG',
      'Antigua & Barbuda',
      'Antigua and Barbuda',
    ]),
    BusinessCountry('SA', 'Arabie saoudite', [
      'Kingdom of Saudi Arabia',
      'SAU',
      'Saudi Arabia',
    ]),
    BusinessCountry('AR', 'Argentine', [
      'ARG',
      'Argentina',
      'Argentine Republic',
    ]),
    BusinessCountry('AM', 'Arménie', ['ARM', 'Armenia', 'Republic of Armenia']),
    BusinessCountry('AW', 'Aruba', ['ABW', 'Aruba']),
    BusinessCountry('AU', 'Australie', ['AUS', 'Australia']),
    BusinessCountry('AT', 'Autriche', [
      'AUT',
      'Austria',
      'Republic of Austria',
      'Österreich',
    ]),
    BusinessCountry('AZ', 'Azerbaïdjan', [
      'AZE',
      'Azerbaijan',
      'Republic of Azerbaijan',
    ]),
    BusinessCountry('BS', 'Bahamas', [
      'BHS',
      'Bahamas',
      'Commonwealth of the Bahamas',
    ]),
    BusinessCountry('BH', 'Bahreïn', ['BHR', 'Bahrain', 'Kingdom of Bahrain']),
    BusinessCountry('BD', 'Bangladesh', [
      'BGD',
      'Bangladesh',
      'People\'s Republic of Bangladesh',
    ]),
    BusinessCountry('BB', 'Barbade', ['BRB', 'Barbados']),
    BusinessCountry('BE', 'Belgique', ['BEL', 'Belgium', 'Kingdom of Belgium']),
    BusinessCountry('BZ', 'Belize', ['BLZ', 'Belize']),
    BusinessCountry('BJ', 'Bénin', ['BEN', 'Benin', 'Republic of Benin']),
    BusinessCountry('BM', 'Bermudes', ['BMU', 'Bermuda']),
    BusinessCountry('BT', 'Bhoutan', ['BTN', 'Bhutan', 'Kingdom of Bhutan']),
    BusinessCountry('BY', 'Biélorussie', [
      'BLR',
      'Belarus',
      'Republic of Belarus',
    ]),
    BusinessCountry('BO', 'Bolivie', [
      'BOL',
      'Bolivia',
      'Bolivia, Plurinational State of',
      'Plurinational State of Bolivia',
    ]),
    BusinessCountry('BA', 'Bosnie-Herzégovine', [
      'BIH',
      'Bosnia & Herzegovina',
      'Bosnia and Herzegovina',
      'Republic of Bosnia and Herzegovina',
    ]),
    BusinessCountry('BW', 'Botswana', [
      'BWA',
      'Botswana',
      'Republic of Botswana',
    ]),
    BusinessCountry('BR', 'Brésil', [
      'BRA',
      'Brazil',
      'Federative Republic of Brazil',
    ]),
    BusinessCountry('BN', 'Brunei', ['BRN', 'Brunei', 'Brunei Darussalam']),
    BusinessCountry('BG', 'Bulgarie', [
      'BGR',
      'Bulgaria',
      'Republic of Bulgaria',
    ]),
    BusinessCountry('BF', 'Burkina Faso', ['BFA', 'Burkina Faso']),
    BusinessCountry('BI', 'Burundi', ['BDI', 'Burundi', 'Republic of Burundi']),
    BusinessCountry('KH', 'Cambodge', [
      'Cambodia',
      'KHM',
      'Kingdom of Cambodia',
    ]),
    BusinessCountry('CM', 'Cameroun', [
      'CMR',
      'Cameroon',
      'Republic of Cameroon',
    ]),
    BusinessCountry('CA', 'Canada', ['CAN', 'Canada']),
    BusinessCountry('CV', 'Cap-Vert', [
      'CPV',
      'Cabo Verde',
      'Cape Verde',
      'Republic of Cabo Verde',
    ]),
    BusinessCountry('CL', 'Chili', ['CHL', 'Chile', 'Republic of Chile']),
    BusinessCountry('CN', 'Chine', [
      'CHN',
      'China',
      'People\'s Republic of China',
    ]),
    BusinessCountry('CY', 'Chypre', ['CYP', 'Cyprus', 'Republic of Cyprus']),
    BusinessCountry('CO', 'Colombie', [
      'COL',
      'Colombia',
      'Republic of Colombia',
    ]),
    BusinessCountry('KM', 'Comores', [
      'COM',
      'Comoros',
      'Union of the Comoros',
    ]),
    BusinessCountry('CG', 'Congo-Brazzaville', [
      'COG',
      'Congo - Brazzaville',
      'Republic of the Congo',
    ]),
    BusinessCountry('CD', 'Congo-Kinshasa', [
      'COD',
      'Congo - Kinshasa',
      'Congo, The Democratic Republic of the',
    ]),
    BusinessCountry('KP', 'Corée du Nord', [
      'Democratic People\'s Republic of Korea',
      'Korea, Democratic People\'s Republic of',
      'North Korea',
      'PRK',
    ]),
    BusinessCountry('KR', 'Corée du Sud', [
      'KOR',
      'Korea, Republic of',
      'South Korea',
    ]),
    BusinessCountry('CR', 'Costa Rica', [
      'CRI',
      'Costa Rica',
      'Republic of Costa Rica',
    ]),
    BusinessCountry('CI', 'Côte d’Ivoire', [
      'CIV',
      'Cote d\'Ivoire',
      'Côte d\'Ivoire',
      'Côte d’Ivoire',
      'Ivory Coast',
      'Republic of Côte d\'Ivoire',
    ]),
    BusinessCountry('HR', 'Croatie', ['Croatia', 'HRV', 'Republic of Croatia']),
    BusinessCountry('CU', 'Cuba', ['CUB', 'Cuba', 'Republic of Cuba']),
    BusinessCountry('CW', 'Curaçao', ['CUW', 'Curaçao']),
    BusinessCountry('DK', 'Danemark', ['DNK', 'Denmark', 'Kingdom of Denmark']),
    BusinessCountry('DJ', 'Djibouti', [
      'DJI',
      'Djibouti',
      'Republic of Djibouti',
    ]),
    BusinessCountry('DM', 'Dominique', [
      'Commonwealth of Dominica',
      'DMA',
      'Dominica',
    ]),
    BusinessCountry('EG', 'Égypte', ['Arab Republic of Egypt', 'EGY', 'Egypt']),
    BusinessCountry('AE', 'Émirats arabes unis', [
      'ARE',
      'United Arab Emirates',
    ]),
    BusinessCountry('EC', 'Équateur', [
      'ECU',
      'Ecuador',
      'Republic of Ecuador',
    ]),
    BusinessCountry('ER', 'Érythrée', [
      'ERI',
      'Eritrea',
      'the State of Eritrea',
    ]),
    BusinessCountry('ES', 'Espagne', ['ESP', 'Kingdom of Spain', 'Spain']),
    BusinessCountry('EE', 'Estonie', ['EST', 'Estonia', 'Republic of Estonia']),
    BusinessCountry('SZ', 'Eswatini', [
      'Eswatini',
      'Kingdom of Eswatini',
      'SWZ',
    ]),
    BusinessCountry('VA', 'État de la Cité du Vatican', [
      'Holy See (Vatican City State)',
      'VAT',
      'Vatican City',
    ]),
    BusinessCountry('US', 'États-Unis', [
      'Etats-Unis',
      'U.S.A.',
      'USA',
      'United States',
      'United States of America',
      'États Unis',
    ]),
    BusinessCountry('ET', 'Éthiopie', [
      'ETH',
      'Ethiopia',
      'Federal Democratic Republic of Ethiopia',
    ]),
    BusinessCountry('FJ', 'Fidji', ['FJI', 'Fiji', 'Republic of Fiji']),
    BusinessCountry('FI', 'Finlande', [
      'FIN',
      'Finland',
      'Republic of Finland',
    ]),
    BusinessCountry('FR', 'France', ['FRA', 'France', 'French Republic']),
    BusinessCountry('GA', 'Gabon', ['GAB', 'Gabon', 'Gabonese Republic']),
    BusinessCountry('GM', 'Gambie', [
      'GMB',
      'Gambia',
      'Republic of the Gambia',
    ]),
    BusinessCountry('GE', 'Géorgie', ['GEO', 'Georgia']),
    BusinessCountry('GS', 'Géorgie du Sud-et-les Îles Sandwich du Sud', [
      'SGS',
      'South Georgia & South Sandwich Islands',
      'South Georgia and the South Sandwich Islands',
    ]),
    BusinessCountry('GH', 'Ghana', ['GHA', 'Ghana', 'Republic of Ghana']),
    BusinessCountry('GI', 'Gibraltar', ['GIB', 'Gibraltar']),
    BusinessCountry('GR', 'Grèce', ['GRC', 'Greece', 'Hellenic Republic']),
    BusinessCountry('GD', 'Grenade', ['GRD', 'Grenada']),
    BusinessCountry('GL', 'Groenland', ['GRL', 'Greenland']),
    BusinessCountry('GP', 'Guadeloupe', ['GLP', 'Guadeloupe']),
    BusinessCountry('GU', 'Guam', ['GUM', 'Guam']),
    BusinessCountry('GT', 'Guatemala', [
      'GTM',
      'Guatemala',
      'Republic of Guatemala',
    ]),
    BusinessCountry('GG', 'Guernesey', ['GGY', 'Guernsey']),
    BusinessCountry('GN', 'Guinée', ['GIN', 'Guinea', 'Republic of Guinea']),
    BusinessCountry('GQ', 'Guinée équatoriale', [
      'Equatorial Guinea',
      'GNQ',
      'Republic of Equatorial Guinea',
    ]),
    BusinessCountry('GW', 'Guinée-Bissau', [
      'GNB',
      'Guinea-Bissau',
      'Republic of Guinea-Bissau',
    ]),
    BusinessCountry('GY', 'Guyana', ['GUY', 'Guyana', 'Republic of Guyana']),
    BusinessCountry('GF', 'Guyane française', ['French Guiana', 'GUF']),
    BusinessCountry('HT', 'Haïti', ['HTI', 'Haiti', 'Republic of Haiti']),
    BusinessCountry('HN', 'Honduras', [
      'HND',
      'Honduras',
      'Republic of Honduras',
    ]),
    BusinessCountry('HU', 'Hongrie', ['HUN', 'Hungary']),
    BusinessCountry('BV', 'Île Bouvet', ['BVT', 'Bouvet Island']),
    BusinessCountry('CX', 'Île Christmas', ['CXR', 'Christmas Island']),
    BusinessCountry('IM', 'Île de Man', ['IMN', 'Isle of Man']),
    BusinessCountry('NF', 'Île Norfolk', ['NFK', 'Norfolk Island']),
    BusinessCountry('AX', 'Îles Åland', ['ALA', 'Åland Islands']),
    BusinessCountry('KY', 'Îles Caïmans', ['CYM', 'Cayman Islands']),
    BusinessCountry('CC', 'Îles Cocos', ['CCK', 'Cocos (Keeling) Islands']),
    BusinessCountry('CK', 'Îles Cook', ['COK', 'Cook Islands']),
    BusinessCountry('FO', 'Îles Féroé', ['FRO', 'Faroe Islands']),
    BusinessCountry('HM', 'Îles Heard-et-MacDonald', [
      'HMD',
      'Heard & McDonald Islands',
      'Heard Island and McDonald Islands',
    ]),
    BusinessCountry('FK', 'Îles Malouines', [
      'FLK',
      'Falkland Islands',
      'Falkland Islands (Malvinas)',
    ]),
    BusinessCountry('MP', 'Îles Mariannes du Nord', [
      'Commonwealth of the Northern Mariana Islands',
      'MNP',
      'Northern Mariana Islands',
    ]),
    BusinessCountry('MH', 'Îles Marshall', [
      'MHL',
      'Marshall Islands',
      'Republic of the Marshall Islands',
    ]),
    BusinessCountry('UM', 'Îles mineures éloignées des États-Unis', [
      'U.S. Outlying Islands',
      'UMI',
      'United States Minor Outlying Islands',
    ]),
    BusinessCountry('PN', 'Îles Pitcairn', [
      'PCN',
      'Pitcairn',
      'Pitcairn Islands',
    ]),
    BusinessCountry('SB', 'Îles Salomon', ['SLB', 'Solomon Islands']),
    BusinessCountry('TC', 'Îles Turques-et-Caïques', [
      'TCA',
      'Turks & Caicos Islands',
      'Turks and Caicos Islands',
    ]),
    BusinessCountry('VG', 'Îles Vierges britanniques', [
      'British Virgin Islands',
      'VGB',
      'Virgin Islands, British',
    ]),
    BusinessCountry('VI', 'Îles Vierges des États-Unis', [
      'U.S. Virgin Islands',
      'VIR',
      'Virgin Islands of the United States',
      'Virgin Islands, U.S.',
    ]),
    BusinessCountry('IN', 'Inde', ['IND', 'India', 'Republic of India']),
    BusinessCountry('ID', 'Indonésie', [
      'IDN',
      'Indonesia',
      'Republic of Indonesia',
    ]),
    BusinessCountry('IQ', 'Irak', ['IRQ', 'Iraq', 'Republic of Iraq']),
    BusinessCountry('IR', 'Iran', [
      'IRN',
      'Iran',
      'Iran, Islamic Republic of',
      'Islamic Republic of Iran',
    ]),
    BusinessCountry('IE', 'Irlande', ['IRL', 'Ireland']),
    BusinessCountry('IS', 'Islande', ['ISL', 'Iceland', 'Republic of Iceland']),
    BusinessCountry('IL', 'Israël', ['ISR', 'Israel', 'State of Israel']),
    BusinessCountry('IT', 'Italie', ['ITA', 'Italian Republic', 'Italy']),
    BusinessCountry('JM', 'Jamaïque', ['JAM', 'Jamaica']),
    BusinessCountry('JP', 'Japon', ['JPN', 'Japan']),
    BusinessCountry('JE', 'Jersey', ['JEY', 'Jersey']),
    BusinessCountry('JO', 'Jordanie', [
      'Hashemite Kingdom of Jordan',
      'JOR',
      'Jordan',
    ]),
    BusinessCountry('KZ', 'Kazakhstan', [
      'KAZ',
      'Kazakhstan',
      'Republic of Kazakhstan',
    ]),
    BusinessCountry('KE', 'Kenya', ['KEN', 'Kenya', 'Republic of Kenya']),
    BusinessCountry('KG', 'Kirghizstan', [
      'KGZ',
      'Kyrgyz Republic',
      'Kyrgyzstan',
    ]),
    BusinessCountry('KI', 'Kiribati', [
      'KIR',
      'Kiribati',
      'Republic of Kiribati',
    ]),
    BusinessCountry('XK', 'Kosovo', ['Kosovo', 'XKX']),
    BusinessCountry('KW', 'Koweït', ['KWT', 'Kuwait', 'State of Kuwait']),
    BusinessCountry('RE', 'La Réunion', ['REU', 'Réunion']),
    BusinessCountry('LA', 'Laos', [
      'LAO',
      'Lao People\'s Democratic Republic',
      'Laos',
    ]),
    BusinessCountry('LS', 'Lesotho', ['Kingdom of Lesotho', 'LSO', 'Lesotho']),
    BusinessCountry('LV', 'Lettonie', ['LVA', 'Latvia', 'Republic of Latvia']),
    BusinessCountry('LB', 'Liban', ['LBN', 'Lebanese Republic', 'Lebanon']),
    BusinessCountry('LR', 'Liberia', ['LBR', 'Liberia', 'Republic of Liberia']),
    BusinessCountry('LY', 'Libye', ['LBY', 'Libya']),
    BusinessCountry('LI', 'Liechtenstein', [
      'LIE',
      'Liechtenstein',
      'Principality of Liechtenstein',
    ]),
    BusinessCountry('LT', 'Lituanie', [
      'LTU',
      'Lithuania',
      'Republic of Lithuania',
    ]),
    BusinessCountry('LU', 'Luxembourg', [
      'Grand Duchy of Luxembourg',
      'LUX',
      'Luxembourg',
    ]),
    BusinessCountry('MK', 'Macédoine du Nord', [
      'MKD',
      'North Macedonia',
      'Republic of North Macedonia',
    ]),
    BusinessCountry('MG', 'Madagascar', [
      'MDG',
      'Madagascar',
      'Republic of Madagascar',
    ]),
    BusinessCountry('MY', 'Malaisie', ['MYS', 'Malaysia']),
    BusinessCountry('MW', 'Malawi', ['MWI', 'Malawi', 'Republic of Malawi']),
    BusinessCountry('MV', 'Maldives', [
      'MDV',
      'Maldives',
      'Republic of Maldives',
    ]),
    BusinessCountry('ML', 'Mali', ['MLI', 'Mali', 'Republic of Mali']),
    BusinessCountry('MT', 'Malte', ['MLT', 'Malta', 'Republic of Malta']),
    BusinessCountry('MA', 'Maroc', ['Kingdom of Morocco', 'MAR', 'Morocco']),
    BusinessCountry('MQ', 'Martinique', ['MTQ', 'Martinique']),
    BusinessCountry('MU', 'Maurice', [
      'MUS',
      'Mauritius',
      'Republic of Mauritius',
    ]),
    BusinessCountry('MR', 'Mauritanie', [
      'Islamic Republic of Mauritania',
      'MRT',
      'Mauritania',
    ]),
    BusinessCountry('YT', 'Mayotte', ['MYT', 'Mayotte']),
    BusinessCountry('MX', 'Mexique', [
      'MEX',
      'Mexico',
      'United Mexican States',
    ]),
    BusinessCountry('FM', 'Micronésie', [
      'FSM',
      'Federated States of Micronesia',
      'Micronesia',
      'Micronesia, Federated States of',
    ]),
    BusinessCountry('MD', 'Moldavie', [
      'MDA',
      'Moldova',
      'Moldova, Republic of',
      'Republic of Moldova',
    ]),
    BusinessCountry('MC', 'Monaco', [
      'MCO',
      'Monaco',
      'Principality of Monaco',
    ]),
    BusinessCountry('MN', 'Mongolie', ['MNG', 'Mongolia']),
    BusinessCountry('ME', 'Monténégro', ['MNE', 'Montenegro']),
    BusinessCountry('MS', 'Montserrat', ['MSR', 'Montserrat']),
    BusinessCountry('MZ', 'Mozambique', [
      'MOZ',
      'Mozambique',
      'Republic of Mozambique',
    ]),
    BusinessCountry('MM', 'Myanmar (Birmanie)', [
      'MMR',
      'Myanmar',
      'Myanmar (Burma)',
      'Republic of Myanmar',
    ]),
    BusinessCountry('NA', 'Namibie', ['NAM', 'Namibia', 'Republic of Namibia']),
    BusinessCountry('NR', 'Nauru', ['NRU', 'Nauru', 'Republic of Nauru']),
    BusinessCountry('NP', 'Népal', [
      'Federal Democratic Republic of Nepal',
      'NPL',
      'Nepal',
    ]),
    BusinessCountry('NI', 'Nicaragua', [
      'NIC',
      'Nicaragua',
      'Republic of Nicaragua',
    ]),
    BusinessCountry('NE', 'Niger', ['NER', 'Niger', 'Republic of the Niger']),
    BusinessCountry('NG', 'Nigeria', [
      'Federal Republic of Nigeria',
      'NGA',
      'Nigeria',
    ]),
    BusinessCountry('NU', 'Niue', ['NIU', 'Niue']),
    BusinessCountry('NO', 'Norvège', ['Kingdom of Norway', 'NOR', 'Norway']),
    BusinessCountry('NC', 'Nouvelle-Calédonie', ['NCL', 'New Caledonia']),
    BusinessCountry('NZ', 'Nouvelle-Zélande', ['NZL', 'New Zealand']),
    BusinessCountry('OM', 'Oman', ['OMN', 'Oman', 'Sultanate of Oman']),
    BusinessCountry('UG', 'Ouganda', ['Republic of Uganda', 'UGA', 'Uganda']),
    BusinessCountry('UZ', 'Ouzbékistan', [
      'Republic of Uzbekistan',
      'UZB',
      'Uzbekistan',
    ]),
    BusinessCountry('PK', 'Pakistan', [
      'Islamic Republic of Pakistan',
      'PAK',
      'Pakistan',
    ]),
    BusinessCountry('PW', 'Palaos', ['PLW', 'Palau', 'Republic of Palau']),
    BusinessCountry('PA', 'Panama', ['PAN', 'Panama', 'Republic of Panama']),
    BusinessCountry('PG', 'Papouasie-Nouvelle-Guinée', [
      'Independent State of Papua New Guinea',
      'PNG',
      'Papua New Guinea',
    ]),
    BusinessCountry('PY', 'Paraguay', [
      'PRY',
      'Paraguay',
      'Republic of Paraguay',
    ]),
    BusinessCountry('NL', 'Pays-Bas', [
      'Holland',
      'Hollande',
      'Kingdom of the Netherlands',
      'NLD',
      'Nederland',
      'Netherlands',
    ]),
    BusinessCountry('BQ', 'Pays-Bas caribéens', [
      'BES',
      'Bonaire, Sint Eustatius and Saba',
      'Caribbean Netherlands',
    ]),
    BusinessCountry('PE', 'Pérou', ['PER', 'Peru', 'Republic of Peru']),
    BusinessCountry('PH', 'Philippines', [
      'PHL',
      'Philippines',
      'Republic of the Philippines',
    ]),
    BusinessCountry('PL', 'Pologne', ['POL', 'Poland', 'Republic of Poland']),
    BusinessCountry('PF', 'Polynésie française', ['French Polynesia', 'PYF']),
    BusinessCountry('PR', 'Porto Rico', ['PRI', 'Puerto Rico']),
    BusinessCountry('PT', 'Portugal', [
      'PRT',
      'Portugal',
      'Portuguese Republic',
    ]),
    BusinessCountry('QA', 'Qatar', ['QAT', 'Qatar', 'State of Qatar']),
    BusinessCountry('HK', 'R.A.S. chinoise de Hong Kong', [
      'HKG',
      'Hong Kong',
      'Hong Kong SAR China',
      'Hong Kong Special Administrative Region of China',
    ]),
    BusinessCountry('MO', 'R.A.S. chinoise de Macao', [
      'MAC',
      'Macao',
      'Macao SAR China',
      'Macao Special Administrative Region of China',
    ]),
    BusinessCountry('CF', 'République centrafricaine', [
      'CAF',
      'Central African Republic',
    ]),
    BusinessCountry('DO', 'République dominicaine', [
      'DOM',
      'Dominican Republic',
    ]),
    BusinessCountry('RO', 'Roumanie', ['ROU', 'Romania']),
    BusinessCountry('GB', 'Royaume-Uni', [
      'GBR',
      'Grande-Bretagne',
      'Great Britain',
      'Royaume Uni',
      'UK',
      'United Kingdom',
      'United Kingdom of Great Britain and Northern Ireland',
    ]),
    BusinessCountry('RU', 'Russie', ['RUS', 'Russia', 'Russian Federation']),
    BusinessCountry('RW', 'Rwanda', ['RWA', 'Rwanda', 'Rwandese Republic']),
    BusinessCountry('EH', 'Sahara occidental', ['ESH', 'Western Sahara']),
    BusinessCountry('BL', 'Saint-Barthélemy', [
      'BLM',
      'Saint Barthélemy',
      'St. Barthélemy',
    ]),
    BusinessCountry('KN', 'Saint-Christophe-et-Niévès', [
      'KNA',
      'Saint Kitts and Nevis',
      'St. Kitts & Nevis',
    ]),
    BusinessCountry('SM', 'Saint-Marin', [
      'Republic of San Marino',
      'SMR',
      'San Marino',
    ]),
    BusinessCountry('MF', 'Saint-Martin', [
      'MAF',
      'Saint Martin (French part)',
      'St. Martin',
    ]),
    BusinessCountry('SX', 'Saint-Martin (partie néerlandaise)', [
      'SXM',
      'Sint Maarten',
      'Sint Maarten (Dutch part)',
    ]),
    BusinessCountry('PM', 'Saint-Pierre-et-Miquelon', [
      'SPM',
      'Saint Pierre and Miquelon',
      'St. Pierre & Miquelon',
    ]),
    BusinessCountry('VC', 'Saint-Vincent-et-les Grenadines', [
      'Saint Vincent and the Grenadines',
      'St. Vincent & Grenadines',
      'VCT',
    ]),
    BusinessCountry('SH', 'Sainte-Hélène', [
      'SHN',
      'Saint Helena, Ascension and Tristan da Cunha',
      'St. Helena',
    ]),
    BusinessCountry('LC', 'Sainte-Lucie', ['LCA', 'Saint Lucia', 'St. Lucia']),
    BusinessCountry('SV', 'Salvador', [
      'El Salvador',
      'Republic of El Salvador',
      'SLV',
    ]),
    BusinessCountry('WS', 'Samoa', [
      'Independent State of Samoa',
      'Samoa',
      'WSM',
    ]),
    BusinessCountry('AS', 'Samoa américaines', ['ASM', 'American Samoa']),
    BusinessCountry('ST', 'Sao Tomé-et-Principe', [
      'Democratic Republic of Sao Tome and Principe',
      'STP',
      'Sao Tome and Principe',
      'São Tomé & Príncipe',
    ]),
    BusinessCountry('SN', 'Sénégal', ['Republic of Senegal', 'SEN', 'Senegal']),
    BusinessCountry('RS', 'Serbie', ['Republic of Serbia', 'SRB', 'Serbia']),
    BusinessCountry('SC', 'Seychelles', [
      'Republic of Seychelles',
      'SYC',
      'Seychelles',
    ]),
    BusinessCountry('SL', 'Sierra Leone', [
      'Republic of Sierra Leone',
      'SLE',
      'Sierra Leone',
    ]),
    BusinessCountry('SG', 'Singapour', [
      'Republic of Singapore',
      'SGP',
      'Singapore',
    ]),
    BusinessCountry('SK', 'Slovaquie', ['SVK', 'Slovak Republic', 'Slovakia']),
    BusinessCountry('SI', 'Slovénie', [
      'Republic of Slovenia',
      'SVN',
      'Slovenia',
    ]),
    BusinessCountry('SO', 'Somalie', [
      'Federal Republic of Somalia',
      'SOM',
      'Somalia',
    ]),
    BusinessCountry('SD', 'Soudan', ['Republic of the Sudan', 'SDN', 'Sudan']),
    BusinessCountry('SS', 'Soudan du Sud', [
      'Republic of South Sudan',
      'SSD',
      'South Sudan',
    ]),
    BusinessCountry('LK', 'Sri Lanka', [
      'Democratic Socialist Republic of Sri Lanka',
      'LKA',
      'Sri Lanka',
    ]),
    BusinessCountry('SE', 'Suède', ['Kingdom of Sweden', 'SWE', 'Sweden']),
    BusinessCountry('CH', 'Suisse', [
      'CHE',
      'Schweiz',
      'Svizzera',
      'Swiss Confederation',
      'Switzerland',
    ]),
    BusinessCountry('SR', 'Suriname', [
      'Republic of Suriname',
      'SUR',
      'Suriname',
    ]),
    BusinessCountry('SJ', 'Svalbard et Jan Mayen', [
      'SJM',
      'Svalbard & Jan Mayen',
      'Svalbard and Jan Mayen',
    ]),
    BusinessCountry('SY', 'Syrie', ['SYR', 'Syria', 'Syrian Arab Republic']),
    BusinessCountry('TJ', 'Tadjikistan', [
      'Republic of Tajikistan',
      'TJK',
      'Tajikistan',
    ]),
    BusinessCountry('TW', 'Taïwan', [
      'TWN',
      'Taiwan',
      'Taiwan, Province of China',
    ]),
    BusinessCountry('TZ', 'Tanzanie', [
      'TZA',
      'Tanzania',
      'Tanzania, United Republic of',
      'United Republic of Tanzania',
    ]),
    BusinessCountry('TD', 'Tchad', ['Chad', 'Republic of Chad', 'TCD']),
    BusinessCountry('CZ', 'Tchéquie', ['CZE', 'Czech Republic', 'Czechia']),
    BusinessCountry('TF', 'Terres australes françaises', [
      'ATF',
      'French Southern Territories',
    ]),
    BusinessCountry('IO', 'Territoire britannique de l’océan Indien', [
      'British Indian Ocean Territory',
      'IOT',
    ]),
    BusinessCountry('PS', 'Territoires palestiniens', [
      'PSE',
      'Palestine',
      'Palestine, State of',
      'Palestinian Territories',
      'the State of Palestine',
    ]),
    BusinessCountry('TH', 'Thaïlande', [
      'Kingdom of Thailand',
      'THA',
      'Thailand',
    ]),
    BusinessCountry('TL', 'Timor oriental', [
      'Democratic Republic of Timor-Leste',
      'TLS',
      'Timor-Leste',
    ]),
    BusinessCountry('TG', 'Togo', ['TGO', 'Togo', 'Togolese Republic']),
    BusinessCountry('TK', 'Tokelau', ['TKL', 'Tokelau']),
    BusinessCountry('TO', 'Tonga', ['Kingdom of Tonga', 'TON', 'Tonga']),
    BusinessCountry('TT', 'Trinité-et-Tobago', [
      'Republic of Trinidad and Tobago',
      'TTO',
      'Trinidad & Tobago',
      'Trinidad and Tobago',
    ]),
    BusinessCountry('TN', 'Tunisie', ['Republic of Tunisia', 'TUN', 'Tunisia']),
    BusinessCountry('TM', 'Turkménistan', ['TKM', 'Turkmenistan']),
    BusinessCountry('TR', 'Turquie', [
      'Republic of Türkiye',
      'TUR',
      'Turkey',
      'Türkiye',
    ]),
    BusinessCountry('TV', 'Tuvalu', ['TUV', 'Tuvalu']),
    BusinessCountry('UA', 'Ukraine', ['UKR', 'Ukraine']),
    BusinessCountry('UY', 'Uruguay', [
      'Eastern Republic of Uruguay',
      'URY',
      'Uruguay',
    ]),
    BusinessCountry('VU', 'Vanuatu', ['Republic of Vanuatu', 'VUT', 'Vanuatu']),
    BusinessCountry('VE', 'Venezuela', [
      'Bolivarian Republic of Venezuela',
      'VEN',
      'Venezuela',
      'Venezuela, Bolivarian Republic of',
    ]),
    BusinessCountry('VN', 'Viêt Nam', [
      'Socialist Republic of Viet Nam',
      'VNM',
      'Viet Nam',
      'Vietnam',
    ]),
    BusinessCountry('WF', 'Wallis-et-Futuna', [
      'WLF',
      'Wallis & Futuna',
      'Wallis and Futuna',
    ]),
    BusinessCountry('YE', 'Yémen', ['Republic of Yemen', 'YEM', 'Yemen']),
    BusinessCountry('ZM', 'Zambie', ['Republic of Zambia', 'ZMB', 'Zambia']),
    BusinessCountry('ZW', 'Zimbabwe', [
      'Republic of Zimbabwe',
      'ZWE',
      'Zimbabwe',
    ]),
  ];

  static String normalize(String value) {
    var text = value.trim().toLowerCase();
    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ø': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'œ': 'oe',
      'æ': 'ae',
    };
    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static BusinessCountry? byCode(String? value) {
    final code = value?.trim().toUpperCase();
    for (final country in all) {
      if (country.code == code) {
        return country;
      }
    }
    return null;
  }

  static BusinessCountry? find(String? value) {
    final query = normalize(value ?? '');
    if (query.isEmpty || isPlaceholder(value)) {
      return null;
    }
    final matches = all
        .where(
          (country) =>
              normalize(country.code) == query ||
              normalize(country.name) == query ||
              country.aliases.any((alias) => normalize(alias) == query),
        )
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  static bool isPlaceholder(String? value) => const {
    '',
    'autrepays',
    'other',
    'othercountry',
    'unknown',
    'inconnu',
    'nonrenseigne',
    'null',
  }.contains(normalize(value ?? ''));

  static List<BusinessCountry> search(String value) {
    final query = normalize(value);
    if (query.isEmpty) {
      return List<BusinessCountry>.of(all);
    }
    final exact = find(value);
    final matches = all
        .where(
          (country) =>
              normalize(country.name).contains(query) ||
              normalize(country.code).contains(query) ||
              country.aliases.any((alias) => normalize(alias).contains(query)),
        )
        .toList();
    if (exact != null) {
      matches.remove(exact);
      matches.insert(0, exact);
    }
    return matches;
  }

  /// Saved business information takes priority over device location.
  /// An unknown meaningful country is kept for manual correction.
  static BusinessCountryResolution resolveSaved({
    required Map<String, dynamic> draft,
    required Map<String, dynamic> fields,
    required Map<String, dynamic> profile,
  }) {
    final records = [draft, fields, profile];
    const sources = ['dossier', 'établissement', 'établissement'];
    for (var i = 0; i < records.length; i++) {
      final data = records[i];
      final rawName = data['country'];
      final name = rawName is String ? rawName.trim() : '';
      BusinessCountry? country;
      for (final key in ['countryCode', 'countryIsoCode']) {
        final value = data[key];
        if (value is String) {
          country = byCode(value) ?? find(value);
          if (country != null) {
            break;
          }
        }
      }
      country ??= find(name);
      if (country != null) {
        return BusinessCountryResolution(country, sources[i]);
      }
      if (!isPlaceholder(name)) {
        return BusinessCountryResolution(null, sources[i], unknownName: name);
      }
    }
    return const BusinessCountryResolution(null, '');
  }

  static String registrationLabel(BusinessCountry? country) =>
      switch (country?.code) {
        'FR' => 'SIREN ou SIRET',
        'DE' => 'Numéro officiel / Handelsregister',
        'CH' => 'IDE / UID ou numéro du registre',
        'BE' => 'Numéro BCE',
        'IT' => 'Partita IVA',
        'NL' => 'Numéro KVK',
        _ => 'Numéro officiel d’enregistrement',
      };
}
