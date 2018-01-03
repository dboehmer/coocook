use strict;
use warnings;

# ABSTRACT: copy data to all projects that had been shared before

use DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => 'v6' },
    sub {
        my $schema = shift;

        my @projects = $schema->resultset('Project')->all;

        @projects > 1
          or return;

        ### 1: those records need to be duplicated for each project
        my @tables = qw< Article Quantity Recipe ShopSection Tag TagGroup Unit >;

        my %map;

        for my $table (@tables) {
            print "[Phase 1/3] Copying '$table' data to all projects ...\n";

            my $rows = $schema->resultset($table);

            my $first = $rows->first
              or next;

            my $project_id = $first->get_column('project');                  # randomly selected by 001.sql
            my @other_projects = grep { $_->id != $project_id } @projects;

            # limit to currently existing rows
            $rows = $rows->search( { project => $project_id } );

            while ( my $row = $rows->next ) {
                for my $project (@other_projects) {
                    my $new_row = $row->copy( { project => $project->id } );

                    # store mapping
                    $map{$table}{ $row->id }{ $project->id } = $new_row->id;
                }
            }
        }

        ### 2: those records link to object that have been duplicated
        my %copy = (
            ArticleTag       => { article => 'Article', tag    => 'Tag' },
            ArticleUnit      => { article => 'Article', unit   => 'Unit' },
            RecipeIngredient => { article => 'Article', recipe => 'Recipe', unit => 'Unit' },
            RecipeTag        => { recipe  => 'Recipe',  tag    => 'Tag' },
        );

        while ( my ( $rs => $rels ) = each %copy ) {
            print "[Phase 2/3] Copying '$rs' data to all projects ...\n";

            my $rows = $schema->resultset($rs);

            while ( my $row = $rows->next ) {

                # look up @other_projects for any source ID in the relevant columns
                my ($any_column)   = keys %$rels;
                my $any_rs         = $rels->{$any_column};
                my $any_id         = $row->get_column($any_column);
                my @other_projects = keys %{ $map{$any_rs}{$any_id} };

                # create a copy for each @other_projects
                for my $project (@other_projects) {
                    my %cols;

                    # look up new ID for every relevant column
                    while ( my ( $col => $rs2 ) = each %$rels ) {
                        my $old_id = $row->get_column($col);
                        my $new_id = $cols{$col} = $map{$rs2}{$old_id}{$project}
                          || die "No new ID for $rs2 $old_id in project $project";
                        $old_id != $new_id || die;
                    }

                    $row->copy( \%cols );
                }
            }
        }

        ### 3: those records are already project-specific but IDs might have changed
        my %update = (
            Article => { shop_section => 'ShopSection' },
            Dish    => {
                _attrs      => { join => 'meal', '+columns' => { project => 'meal.project' } },
                from_recipe => 'Recipe',
            },
            DishIngredient => {
                _attrs  => { join => { 'dish' => 'meal' }, '+columns' => { project => 'meal.project' } },
                article => 'Article',
                unit    => 'Unit',
            },
            DishTag => {
                _attrs => { join => { 'dish' => 'meal' }, '+columns' => { project => 'meal.project' } },
                tag    => 'Tag',
            },
            Item => {
                _attrs  => { join => 'purchase_list', '+columns' => { project => 'purchase_list.project' } },
                article => 'Article',
                unit    => 'Unit',
            },
            Quantity => { default_unit => 'Unit' },
            Tag      => { tag_group    => 'TagGroup' },
            Unit     => { quantity     => 'Quantity' },
        );

        while ( my ( $rs => $rels ) = each %update ) {
            print "[Phase 3/3] Update '$rs' data for all new projects ...\n";

            my $rows = $schema->resultset($rs);

            if ( my $attrs = delete $$rels{_attrs} ) {
                $rows = $rows->search( undef, $attrs );
            }

            while ( my $row = $rows->next ) {
                my $project = $row->get_column('project');

                while ( my ( $column => $rs2 ) = each %$rels ) {
                    my $old_id = $row->get_column($column) // next;
                    my $new_id = $map{$rs2}{$old_id}{$project} // next;

                    $row->set_columns( { $column => $new_id } );
                }

                $row->update();
            }
        }
    }
);
