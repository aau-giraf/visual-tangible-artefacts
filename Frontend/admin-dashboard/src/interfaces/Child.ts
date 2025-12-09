import { UserGetDTO } from "./User";

export interface Child extends UserGetDTO {
    caregiver?: UserGetDTO;
}
