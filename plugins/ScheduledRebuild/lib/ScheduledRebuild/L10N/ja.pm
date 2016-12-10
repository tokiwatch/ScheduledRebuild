# $Id$

package ScheduledRebuild::L10N::ja;

use strict;
use base 'ScheduledRebuild::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
    'description of ScheduledRebuild' => 'ScheduledRebuildの説明',
    "ScheduledRebuild enable:" => "プラグインを利用する",
    "ScheduledRebuild target template list:" => "テンプレートIDリスト",
    "RebuildOncetimePerDay target template ids Hint" => "YAML形式でIDと再構築の時刻を定義してください。",
    "ScheduledRebuild last time:" => "最終実行日時"
);

1;
