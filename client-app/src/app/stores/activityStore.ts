import { observable, action, computed } from "mobx";
import { createContext } from "react";
import { IActivity } from "../models/activity";
import agent from "../api/agent";

class ActivityStore {
  @observable activities: IActivity[] = [];
  @observable selectedActivity: IActivity | undefined;
  @observable loadingInitial = false;
  @observable editMode = false;
  @observable submitting = false;

  @computed get activitiesByDate() {
    return this.activities.sort(
      (a, b) => Date.parse(a.date) - Date.parse(b.date)
    );
  }

  @action loadActivities = async () => {
    this.loadingInitial = true;
    try {
      const activities = await agent.Activities.list();
      activities.forEach((activity) => {
        activity.date = activity.date.split(".")[0];
        this.activities.push(activity);
        this.loadingInitial = false;
      });
    } catch (error) {
      console.log(error);
      this.loadingInitial = false;
    }
  };

  @action createActivity = async (activity: IActivity) => {
    this.submitting = true;
    try {
      await agent.Activities.create(activity);
      this.activities.push(activity);
      this.editMode = false;
      this.submitting = false;
    } catch (error) {
      console.log(error);
      this.submitting = false;
    }
  };

  @action openCreateForm = () => {
    this.selectedActivity = undefined;
    this.editMode = true;
  };

  @action selectActivity = (id: string) => {
    this.selectedActivity = this.activities.find(
      (activity) => activity.id === id
    );
    this.editMode = false;
  };
}

export default createContext(new ActivityStore());
