variable "group_names" {
  description = "Map of group keys to display names."
  type        = map(string)
}

variable "group_members" {
  description = "Map of group key -> list of member object IDs to add to the group."
  type        = map(list(string))
  default     = {}
}
