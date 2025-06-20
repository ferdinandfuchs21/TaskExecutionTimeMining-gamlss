import pandas
import datetime

class TransformEventLog:
    def start_end_event_log(event_log,
                            merge_activity_on = ['case:concept:name', 'org:resource', 'concept:name'],
                            timestamp_name = 'time:timestamp',
                            lifecycle_col_name = 'lifecycle:transition',
                            start_name = 'START',
                            complete_name = 'COMPLETE'):
        merged_event_log = pandas.merge(event_log, event_log,
                                    left_on=merge_activity_on,
                                    right_on=merge_activity_on,
                                    suffixes=('_start', '_complete'))
        start_end_event_log = merged_event_log[(merged_event_log[lifecycle_col_name + '_start'] == start_name) & (merged_event_log[lifecycle_col_name + '_complete'] == complete_name)]
        start_end_event_log.loc[:, 'duration'] = start_end_event_log[timestamp_name + '_complete'] - start_end_event_log[timestamp_name + '_start']
        start_end_event_log.loc[:, 'duration_seconds'] =  (start_end_event_log['duration']).astype('timedelta64[s]').astype(int)
        #start_end_event_log = start_end_event_log[start_end_event_log['duration_seconds'] > 0]
        return start_end_event_log
    
    def start_end_event_log_all(event_log,
                            merge_activity_on = ['case:concept:name', 'concept:name'],
                            timestamp_name = 'time:timestamp',
                            lifecycle_col_name = 'lifecycle:transition',
                            start_name_gen = '_start',
                            complete_name_gen = '_complete',
                            unique_column = 'EventID'):
        start_end_event_log = pandas.merge(event_log, event_log,
                                    left_on=merge_activity_on,
                                    right_on=merge_activity_on,
                                    suffixes=(start_name_gen, complete_name_gen))
        
        start_end_event_log.loc[:, 'duration'] = start_end_event_log[timestamp_name + complete_name_gen] - start_end_event_log[timestamp_name + start_name_gen]
        start_end_event_log.loc[:, 'duration_seconds'] = start_end_event_log['duration'] / datetime.timedelta(seconds=1) #(start_end_event_log['duration']).astype('timedelta64[s]').astype(float)
        start_end_event_log.loc[:, 'duration_ms'] = start_end_event_log['duration'] / datetime.timedelta(milliseconds=1)
        start_end_event_log.loc[:, 'duration_hours'] = start_end_event_log['duration'] / datetime.timedelta(hours=1)

        # bad idea: sometimes less than 1 second:
        #start_end_event_log = start_end_event_log[start_end_event_log['duration_seconds'] > 0]
        # better idea:
        start_end_event_log = start_end_event_log[start_end_event_log[timestamp_name + complete_name_gen] > start_end_event_log[timestamp_name + start_name_gen]]
        ixs = start_end_event_log.groupby(unique_column + start_name_gen)['duration_seconds'].idxmin()
        start_end_event_log = start_end_event_log.loc[ixs]


        return start_end_event_log
    
    def add_cumulative_dummies(self, df, case_col, cols_to_encode):
        df_out = df.copy()

        for col in cols_to_encode:
            one_hot = pandas.get_dummies(df_out[col], prefix="")
            one_hot.columns = [c.lstrip('_').replace(" ", "_") for c in one_hot.columns]
            cum_counts = one_hot.groupby(df_out[case_col]).cumsum()
            df_out = pandas.concat([df_out, cum_counts], axis=1)

        return df_out


    def seconds_in_day(event_log,
                    timestamp_name = 'time:timestamp'):
        start_end_event_log = event_log.copy()
        start_end_event_log['seconds_in_day'] = start_end_event_log[timestamp_name].dt.hour * 3600 + \
        start_end_event_log[timestamp_name].dt.minute * 60 + \
        start_end_event_log[timestamp_name].dt.second
        return start_end_event_log
    
    def day_of_week(event_log,
                    timestamp_name = 'time:timestamp',
                    out_col_name = 'day_of_week'):
        event_log[out_col_name] = event_log[timestamp_name].dt.weekday
        return event_log
        
    def index_based_encode(self, event_log, position_attributes, max_prefix_len=3):
        event_log = event_log.dropna(subset=['time:timestamp_start', 'time:timestamp_complete'])
        event_log = event_log.sort_values(by=['case:concept:name', 'time:timestamp_start'])

        encoded_rows = []

        for case_id, case_df in event_log.groupby('case:concept:name'):
            case_df = case_df.reset_index(drop=True)

            for i in range(min(len(case_df), max_prefix_len)):
                row_data = {'case:concept:name': case_id}

                start_timestamp = case_df.loc[i, 'time:timestamp_start']
                end_timestamp = case_df.loc[i, 'time:timestamp_complete']
                duration_sec = (end_timestamp - start_timestamp).total_seconds()

                row_data['time:timestamp_start'] = start_timestamp
                row_data['time:timestamp_complete'] = end_timestamp
                row_data['duration_seconds'] = duration_sec

                for pos in range(max_prefix_len):
                    if pos <= i:
                        event = case_df.iloc[pos]
                        for attr in position_attributes:
                            col_name = f"{attr}_{pos+1}"
                            row_data[col_name] = event.get(attr, None)
                    else:
                        for attr in position_attributes:
                            col_name = f"{attr}_{pos+1}"
                            row_data[col_name] = None

                encoded_rows.append(row_data)

        return pandas.DataFrame(encoded_rows)

    def start_end_event_log_mult(event_log,
                            merge_activity_on = ['case:concept:name', 'concept:name'],
                            timestamp_name = 'time:timestamp',
                            lifecycle_col_name = 'lifecycle:transition',
                            start_name_1 = 'START',
                            start_name_2 = 'START',
                            start_name_3 = 'START',
                            complete_name_1 = 'COMPLETE',
                            complete_name_2 = 'COMPLETE',
                            complete_name_3 = 'COMPLETE',
                            start_name_gen = '_start',
                            complete_name_gen = '_complete',
                            unique_column = 'EventID'):
        merged_event_log = pandas.merge(event_log, event_log,
                                    left_on=merge_activity_on,
                                    right_on=merge_activity_on,
                                    suffixes=(start_name_gen, complete_name_gen))
        start_end_event_log = merged_event_log[
            ((merged_event_log[lifecycle_col_name + start_name_gen] == start_name_1) | (merged_event_log[lifecycle_col_name + start_name_gen] == start_name_2) \
                 | (merged_event_log[lifecycle_col_name + start_name_gen] == start_name_3)) & \
            ((merged_event_log[lifecycle_col_name + complete_name_gen] == complete_name_1) | (merged_event_log[lifecycle_col_name + complete_name_gen] == complete_name_2)
                 |  (merged_event_log[lifecycle_col_name + complete_name_gen] == complete_name_3))
        ]
        start_end_event_log.loc[:, 'duration'] = start_end_event_log[timestamp_name + complete_name_gen] - start_end_event_log[timestamp_name + start_name_gen]
        start_end_event_log.loc[:, 'duration_seconds'] = start_end_event_log['duration'] / datetime.timedelta(seconds=1) #(start_end_event_log['duration']).astype('timedelta64[s]').astype(float)
        start_end_event_log.loc[:, 'duration_ms'] = start_end_event_log['duration'] / datetime.timedelta(milliseconds=1)
        start_end_event_log.loc[:, 'duration_hours'] = start_end_event_log['duration'] / datetime.timedelta(hours=1)

        # bad idea: sometimes less than 1 second:
        #start_end_event_log = start_end_event_log[start_end_event_log['duration_seconds'] > 0]
        # better idea:
        start_end_event_log = start_end_event_log[start_end_event_log[timestamp_name + complete_name_gen] > start_end_event_log[timestamp_name + start_name_gen]]
        ixs = start_end_event_log.groupby(unique_column + start_name_gen)['duration_seconds'].idxmin()
        start_end_event_log = start_end_event_log.loc[ixs]


        return start_end_event_log
    
    def value_count_per_case_without_lifecycle(event_log,
                     column_name,
                     case_name = 'case:concept:name',
                     timestamp_name = 'time:timestamp',
                     unique_id = 'id'):
        value_count = pandas.merge(event_log, event_log,
                                    left_on=[case_name],
                                    right_on=[case_name],
                                    suffixes=('_first', '_second'))

        value_count = value_count[value_count[timestamp_name + '_first'] >= value_count[timestamp_name + '_second']]

        value_count_gb = value_count.groupby([case_name, timestamp_name + '_first', column_name + '_second']).count()[unique_id + '_first'].reset_index()

        pt = pandas.pivot_table(value_count_gb, index=[case_name, timestamp_name + '_first'],
                                columns=[column_name + '_second'],
                                values= unique_id + '_first', aggfunc='sum',
                                fill_value=0)

        value_count_event_log = pandas.merge(event_log, pt,
                        left_on=[case_name, timestamp_name],
                        right_on=[case_name, timestamp_name + '_first'],
                        how='left',
                        suffixes=('_left', '_right'))
        value_count_event_log = value_count_event_log.fillna(0)

        return value_count_event_log
    