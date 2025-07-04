import numpy as np
import pandas
import itertools
from pix_framework.statistics.distribution import DurationDistribution, get_best_fitting_distribution, DistributionType

from event_log_transformer import TransformEventLog

class DumasModel:
    def __init__(self, event_log, resource=True,
                  concept_name = 'concept:name_start',
                  resource_name = 'org:resource'):
        self.min_n = 15
        self.event_log = event_log
        self.resource = resource
        self.concept_name = concept_name
        self.resource_name = resource_name

    def sample(self, concept, resource):
        if self.resource:
            if self.resource_models and (concept, resource) in self.resource_models:
                return self.resource_models[(concept, resource)].generate_sample(1)[0]
            elif concept in self.concept_models:
                return self.concept_models[concept].generate_sample(1)[0]
            else:
                return self.general_model.generate_sample(1)[0]
        else:
            if concept in self.concept_models:
                return self.concept_models[concept].generate_sample(1)[0]
            else:
                return self.general_model.generate_sample(1)[0]

    def get_general_model(self, start_end_event_log):
        return get_best_fitting_distribution(start_end_event_log['duration_seconds'])


    def get_differentiated_durations(self, start_end_event_log, concept, resource):
        el = start_end_event_log[(start_end_event_log[self.concept_name] == concept) &
                                 (start_end_event_log[self.resource_name] == resource)]
        return el['duration_seconds']  

    def get_concept_resource_model(self, start_end_event_log):
        models = dict()
        concepts = start_end_event_log[self.concept_name].unique()
        resources = start_end_event_log[self.resource_name].unique()
        
        for concept, resource in itertools.product(concepts, resources):
            differentiated_durations = self.get_differentiated_durations(start_end_event_log, concept, resource)
            if len(differentiated_durations) >= self.min_n:
                model = get_best_fitting_distribution(differentiated_durations)
                if model.type != DistributionType.FIXED:
                    models[(concept, resource)] = model
        return models

    def get_concept_durations(self, start_end_event_log, concept):
        el = start_end_event_log[start_end_event_log[self.concept_name] == concept]
        return el['duration_seconds']  

    def get_concept_model(self, start_end_event_log):
        models = dict()
        concepts = start_end_event_log[self.concept_name].unique()
        
        for concept in concepts:
            differentiated_durations = self.get_concept_durations(start_end_event_log, concept)
            if len(differentiated_durations) >= self.min_n:
                model = get_best_fitting_distribution(differentiated_durations)
                if model.type != DistributionType.FIXED:
                    models[concept] = model
        return models

    def set_up_models(self):
        self.general_model = self.get_general_model(self.event_log)
        self.concept_models = self.get_concept_model(self.event_log)
        if self.resource:
            self.resource_models = self.get_concept_resource_model(self.event_log)


class DumasModelLifeCycle:
    def __init__(self, event_log, types=['schedule', 'start', 'suspend'],
                 resource=True):
        self.min_n = 15
        self.event_log = event_log
        self.types = types
        self.resource = resource
        #self.parse_event_log()
        #self.set_up_models()
        self.schedule_start_models = None
        self.start_suspend_models = None
        self.suspend_resume_models = None

    def sample_action(self, action, concept, resource):
        if action == 'schedule':
            return self.sample_model(self.general_schedule_start_model, self.schedule_start_models,
                                     concept, resource)
        elif action == 'start':
            return self.sample_model(self.general_start_suspend_model, self.start_suspend_models,
                                     concept, resource)
        elif action == 'suspend':
            return self.sample_model(self.general_suspend_resume_model, self.suspend_resume_models,
                                     concept, resource)

    def sample_model(self, general_model, models, concept, resource):
        if models and (concept, resource) in models:
            return models[(concept, resource)].generate_sample(1)[0]
        else:
            return general_model.generate_sample(1)[0]

    def parse_event_log(self):
        if 'schedule' in self.types:
            self.schedule_start_event_log = TransformEventLog.start_end_event_log_mult(self.event_log.copy(),
                                                                        start_name_1='schedule',
                                                                        complete_name_1 = 'start',
                                                                        complete_name_2 = 'ate_abort',
                                                                        complete_name_3 = 'pi_abort',
                                                                    start_name_gen='_schedule',
                                                                    complete_name_gen='_start')

        if 'start' in self.types:
            self.start_suspend_event_log = TransformEventLog.start_end_event_log_mult(self.event_log.copy(),
                                                                                start_name_1='start',
                                                                                start_name_2='resume',
                                                                                complete_name_1 = 'suspend',
                                                                                complete_name_2 = 'ate_abort',
                                                                                complete_name_3 = 'complete',
                                                                            start_name_gen='_start',
                                                                            complete_name_gen='_complete')

        if 'suspend' in self.types:
            self.suspend_resume_event_log = TransformEventLog.start_end_event_log_mult(self.event_log.copy(),
                                                                                start_name_1='suspend',
                                                                                complete_name_1 = 'resume',
                                                                                complete_name_2 = 'ate_abort',
                                                                                complete_name_3 = 'complete',
                                                                            start_name_gen='_suspend',
                                                                            complete_name_gen='_resume')

    def set_up_models(self):
        if 'schedule' in self.types:
            self.general_schedule_start_model = self.get_general_model(self.schedule_start_event_log)
            if self.resource:
                self.schedule_start_models = self.get_concept_resource_model(self.schedule_start_event_log,
                                                                        '_start')
        if 'start' in self.types:
            self.general_start_suspend_model = self.get_general_model(self.start_suspend_event_log)
            if self.resource:
                self.start_suspend_models = self.get_concept_resource_model(self.start_suspend_event_log,
                                                                        '_complete')
            
        if 'suspend' in self.types:
            self.general_suspend_resume_model = self.get_general_model(self.suspend_resume_event_log)
            if self.resource:
                self.suspend_resume_models = self.get_concept_resource_model(self.suspend_resume_event_log,
                                                                            '_resume')

    def get_general_model(self, start_end_event_log):
        return get_best_fitting_distribution(start_end_event_log['duration_seconds'])

    def get_concept_resource_model(self, start_end_event_log, resource_suffix):
        models = dict()
        concepts = start_end_event_log['concept:name'].unique()
        resources = start_end_event_log['org:resource'+resource_suffix].unique()
        for concept, resource in itertools.product(concepts, resources):
            differentiated_durations = self.get_differentiated_durations(start_end_event_log, concept, resource, resource_suffix)
            if len(differentiated_durations) >= self.min_n:
                model = get_best_fitting_distribution(differentiated_durations)
                if model.type != DistributionType.FIXED:
                    models[(concept, resource)] = model
        return models

    def get_differentiated_durations(self, start_end_event_log, concept, resource, resource_suffix):
        el = start_end_event_log[(start_end_event_log['concept:name'] == concept) &
                                 (start_end_event_log['org:resource'+resource_suffix] == resource)]
        return el['duration_seconds']