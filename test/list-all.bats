#!/usr/bin/env bats
#
# Copyright 2019 asdf-direnv authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

@test "list-all command fails if first line is not the oldest version" {
  run asdf list-all direnv
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "2.3.0" ]
}
