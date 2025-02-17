// Import and register all your controllers from the importmap via controllers/**/*_controller
//= require moment
//= require fullcalendar

import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
eagerLoadControllersFrom("controllers", application);
