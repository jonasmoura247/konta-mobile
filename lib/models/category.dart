import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}

const List<Category> kCategories = [
  Category(id: 'mercado',      name: 'Mercado',      color: AppColors.catMercado,     icon: Icons.shopping_cart),
  Category(id: 'farmacia',     name: 'Farmácia',     color: AppColors.catFarmacia,    icon: Icons.local_pharmacy),
  Category(id: 'lazer',        name: 'Lazer',        color: AppColors.catLazer,       icon: Icons.sports_esports),
  Category(id: 'estudos',      name: 'Estudos',      color: AppColors.catEstudos,     icon: Icons.menu_book),
  Category(id: 'faculdade',    name: 'Faculdade',    color: AppColors.catFaculdade,   icon: Icons.school),
  Category(id: 'roupa',        name: 'Roupa',        color: AppColors.catRoupa,       icon: Icons.checkroom),
  Category(id: 'ifood',        name: 'iFood',        color: AppColors.catIfood,       icon: Icons.delivery_dining),
  Category(id: 'uber',         name: 'Uber',         color: AppColors.catUber,        icon: Icons.local_taxi),
  Category(id: 'gasolina',     name: 'Gasolina',     color: AppColors.catGasolina,    icon: Icons.local_gas_station),
  Category(id: 'saude',        name: 'Saúde',        color: AppColors.catSaude,       icon: Icons.favorite),
  Category(id: 'necessidade',  name: 'Necessidade',  color: AppColors.catNecessidade, icon: Icons.home),
  Category(id: 'apartamento',  name: 'Apartamento',  color: AppColors.catApartamento, icon: Icons.apartment),
  Category(id: 'manutencao',   name: 'Manutenção',   color: AppColors.catManutencao,  icon: Icons.build),
  Category(id: 'presente',     name: 'Presente',     color: AppColors.catPresente,    icon: Icons.card_giftcard),
  Category(id: 'outros',       name: 'Outros',       color: Color(0xFF546E7A),        icon: Icons.more_horiz),
];

Category getCategoryById(String id) =>
    kCategories.firstWhere((c) => c.id == id, orElse: () => kCategories.last);
