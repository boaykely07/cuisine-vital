import { ViewEntity, ViewColumn, PrimaryColumn } from 'typeorm';

@ViewEntity({
  name: 'v_commandes_statuts', 
})
export class CommandeStatutView {
  @PrimaryColumn() // Une vue a besoin d'une clé primaire pour TypeORM
  @ViewColumn()
  statut: string;

  @ViewColumn()
  ordre: number;

  @ViewColumn({ name: 'nb_commandes_individuelles' }) // Mapper le nom de colonne de la DB
  nbCommandesIndividuelles: number;

  @ViewColumn({ name: 'nb_commandes_entreprises' })
  nbCommandesEntreprises: number;

  @ViewColumn({ name: 'total_commandes' })
  totalCommandes: number;
}