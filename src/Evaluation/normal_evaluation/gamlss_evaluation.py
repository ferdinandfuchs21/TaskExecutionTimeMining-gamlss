from normal_evaluation.normal_evaluation import SampleOutcomes_Normal
import numpy as np
from scipy.stats import invgauss
from scipy.stats import skewnorm


class SampleOutcomes_GAMLSS_LogNormal(SampleOutcomes_Normal):
    def __init__(self, event_log, trained_model, **kwargs):
        super().__init__(event_log, **kwargs)

    def sample_end_time(self, seconds_in_day, resource, concept_name,
                        resource_count, activity_count, day_of_week,
                        value):
        
        pred_mu = self.current_event['pred_mu']
        pred_sigma = self.current_event['pred_sigma']
        
        sampled_duration = np.random.lognormal(mean=pred_mu, sigma=pred_sigma)
        
        return sampled_duration

    def sample_case(self, case_log):

        start_time = case_log[self.timestamp_key].min().timestamp()
        current_time = start_time

        for index, current_event in case_log.iterrows():
            self.current_event = current_event
            duration = self.sample_end_time(
                seconds_in_day=None,
                resource=None,
                concept_name=None,
                resource_count=None,
                activity_count=None,
                day_of_week=None,
                value=None
            )
            current_time += duration
            
        return current_time


class SampleOutcomes_GAMLSS_Gamma(SampleOutcomes_Normal):
    def __init__(self, event_log, trained_model, **kwargs):
        super().__init__(event_log, **kwargs)

    def sample_end_time(self, seconds_in_day, resource, concept_name,
                        resource_count, activity_count, day_of_week,
                        value):

        pred_mu = self.current_event['pred_mu']
        pred_sigma = self.current_event['pred_sigma']
        
        shape = (pred_mu / pred_sigma) ** 2
        scale = (pred_sigma ** 2) / pred_mu
        
        sampled_duration = np.random.gamma(shape, scale)
        
        return sampled_duration

    def sample_case(self, case_log):

        start_time = case_log[self.timestamp_key].min().timestamp()
        current_time = start_time

        for index, current_event in case_log.iterrows():
            self.current_event = current_event
            duration = self.sample_end_time(
                seconds_in_day=None,
                resource=None,
                concept_name=None,
                resource_count=None,
                activity_count=None,
                day_of_week=None,
                value=None
            )
            current_time += duration
            
        return current_time
    

class SampleOutcomes_GAMLSS_IG(SampleOutcomes_Normal):
    def __init__(self, event_log, trained_model, **kwargs):
        super().__init__(event_log, **kwargs)

    def sample_end_time(self, seconds_in_day, resource, concept_name,
                        resource_count, activity_count, day_of_week,
                        value):

        pred_mu = self.current_event['pred_mu']
        pred_sigma = self.current_event['pred_sigma']

        # Inverse Gaussian parameterization: scipy uses mean (mu) and shape (lambda)
        # Note: shape parameter lambda = mu^3 / sigma^2 in GAMLSS

        mu = pred_mu
        lam = (pred_mu ** 3) / (pred_sigma ** 2)

        # scipy's invgauss takes mu (mean) and scale = lambda
        sampled_duration = invgauss(mu / lam, scale=lam).rvs()

        return sampled_duration
    
    def sample_case(self, case_log):
        start_time = case_log[self.timestamp_key].min().timestamp()
        current_time = start_time

        for index, current_event in case_log.iterrows():
            self.current_event = current_event
            duration = self.sample_end_time(
                seconds_in_day=None,
                resource=None,
                concept_name=None,
                resource_count=None,
                activity_count=None,
                day_of_week=None,
                value=None
            )
            current_time += duration

class SampleOutcomes_GAMLSS_SN1(SampleOutcomes_Normal):
    def __init__(self, event_log, trained_model, **kwargs):
        super().__init__(event_log, **kwargs)

    def sample_end_time(self, seconds_in_day, resource, concept_name,
                        resource_count, activity_count, day_of_week,
                        value):
        pred_mu = self.current_event['pred_mu']
        pred_sigma = self.current_event['pred_sigma']
        pred_nu = self.current_event['pred_nu']

        if any(x is None for x in [pred_mu, pred_sigma, pred_nu]):
            return None
            
        # Clip sigma to avoid numerical issues
        sigma = max(pred_sigma, 1e-2)

        # Sample from skew normal
        sampled_duration = skewnorm(a=pred_nu, loc=pred_mu, scale=sigma).rvs()
            
        # Ensure duration is positive
        return max(sampled_duration, 0.0)

    def sample_case(self, case_log):
        start_time = case_log[self.timestamp_key].min().timestamp()
        current_time = start_time

        for index, current_event in case_log.iterrows():
            self.current_event = current_event
            duration = self.sample_end_time(
                seconds_in_day=None,
                resource=None,
                concept_name=None,
                resource_count=None,
                activity_count=None,
                day_of_week=None,
                value=None
            )
            if duration is not None:
                current_time += duration

        return current_time