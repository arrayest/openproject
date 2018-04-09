//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

import {QueryFilterInstanceResource} from '../../api/api-v3/hal-resources/query-filter-instance-resource.service';
import {AbstractDateTimeValueController} from '../abstract-filter-date-time-value/abstract-filter-date-time-value.controller'
import {Component, EventEmitter, Inject, Input, Output} from '@angular/core';
import {I18nToken, TimezoneServiceToken} from 'core-app/angular4-transition-utils';

@Component({
  selector: 'filter-date-time-value',
  template: require('!!raw-loader!./filter-date-time-value.component.html')
})
export class FilterDateTimeValueComponent extends AbstractDateTimeValueController {
  @Input() public filter:QueryFilterInstanceResource;
  @Output() public filterChanged:EventEmitter<QueryFilterInstanceResource>;

  constructor(@Inject(I18nToken) readonly I18n:op.I18n,
              @Inject(TimezoneServiceToken) readonly TimezoneService:any) {
    super(I18n, TimezoneService);
  }

  public get value() {
    return this.filter.values[0];
  }

  public set value(val) {
    this.filter.values = [val as string];
    this.filterChanged.emit(this.filter);
  }

  public get lowerBoundary() {
    if (this.value && this.TimezoneService.isValidISODateTime(this.value)) {
      return this.TimezoneService.parseDatetime(this.value);
    }
  }

  public get upperBoundary() {
    if (this.value && this.TimezoneService.isValidISODateTime(this.value)) {
      return this.TimezoneService.parseDatetime(this.value).add(24, 'hours');
    }
  }
}
