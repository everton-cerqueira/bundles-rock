require 'rock/models/blueprints/control'
require 'rock/models/blueprints/pose'
require 'rock/models/blueprints/devices'

using_task_library 'mars'

module Dev::Mars
        device_type "Actuators"
        device_type "AuvController"
        device_type "AuvMotion" do
            provides Base::JointsControlledSystemSrv
        end
        device_type "Camera" do
            provides Base::ImageProviderSrv
        end
        device_type "DepthCamera"
        device_type "ForceTorque6DOF" do
            provides Base::ForceTorqueProviderSrv
        end
        device_type "HighResRangeFinder" do
            provides Base::PointcloudProviderSrv
        end
        device_type "IMU" do
            provides Base::PoseSrv
        end
        device_type "Joints" do
            provides Base::JointsControlledSystemSrv
            provides Base::TransformationSrv
        end
        device_type "RangeFinder" do
            provides Base::PointcloudProviderSrv
        end
        device_type "LaserRangeFinder" do
            provides Base::LaserRangeFinderSrv
        end
        device_type "RotatingLaserRangeFinder" do
            provides Base::PointcloudProviderSrv
        end
        device_type "Sonar" do
            provides Base::SonarScanProviderSrv
        end

end

# This section extends the existing mars simulation tasks, e.g.,
# typically they will be defined in simulation/orogen/mars
module Mars
    class SimulatedDevice < Syskit::Composition
        add Mars::Task, :as => "mars"

        def self.instanciate(*args)
            cmp_task = super
            cmp_task.task_child.should_configure_after cmp_task.mars_child.start_event
            cmp_task
        end
    end


    class Task
        forward :physics_error => :failed

        def configure
            #orocos_task.enable_gui = true
            super
        end
    end
    
    class AuvMotion
        forward :lost_mars_connection => :failed

        driver_for Dev::Mars::AuvMotion, :as => "driver"
        class Cmp < SimulatedDevice
            add Mars::AuvMotion, :as => "task"
            export task_child.command_port
            export task_child.status_port
            provides Base::JointsControlledSystemSrv, :as => 'actuator'
        end
    end

    class AuvController
        forward :lost_mars_connection => :failed
        driver_for Dev::Mars::AuvController, :as => "driver"
        class Cmp < SimulatedDevice
            add Mars::AuvController, :as => "task"
        end
    end

    class IMU
        forward :lost_mars_connection => :failed
        driver_for Dev::Mars::IMU, :as => 'driver'

        transformer do
            transform_output 'orientation_samples', 'imu' => 'world'
        end

        class Cmp < SimulatedDevice
            add [Dev::Mars::IMU,Base::OrientationSrv], :as => "task"
            export task_child.orientation_samples_port
            provides Base::PoseSrv, :as  => "pose"
        end
    end

    class Sonar
        forward :lost_mars_connection => :failed
        driver_for Dev::Mars::Sonar, :as => "driver"

        class Cmp < SimulatedDevice
            add [Dev::Mars::Sonar,Base::SonarScanProviderSrv], :as => "task"
            export task_child.sonarscan_port
            provides Base::SonarScanProviderSrv, :as  => "scan"
        end
    end

    class Camera
        forward :lost_mars_connection => :failed
        driver_for Dev::Mars::Camera, :as => "driver"

        class Cmp < SimulatedDevice
            add [Dev::Mars::Camera,Base::ImageProviderSrv], :as => "task"
            export task_child.frame_port
            provides Base::ImageProviderSrv, :as => 'camera'
        end
    end

    class Joints
        forward :lost_mars_connection => :failed
        driver_for Dev::Mars::Joints, :as => "driver"

        class Cmp < SimulatedDevice
            add [Dev::Mars::Joints,Base::JointsControlledSystemSrv,Base::TransformationSrv], :as => "task"
            export task_child.command_in_port
            export task_child.status_out_port
            provides Base::JointsControlledSystemSrv, :as => 'actuators'

            export task_child.transformation_port
            provides Base::TransformationSrv, :as => 'transformation'
        end
    end
    
    class ForceTorque6DOF
      forward :lost_mars_connection => :failed
      driver_for Dev::Mars::ForceTorque6DOF, :as => "driver"

      class Cmp < SimulatedDevice
          add [Dev::Mars::ForceTorque6DOF,Base::ForceTorqueProviderSrv], :as => "task"
          export task_child.force_torque_port
          provides Base::ForceTorqueProviderSrv, :as => "force_torque"
      end
    end

    class LaserRangeFinder
      forward :lost_mars_connection => :failed
      driver_for Dev::Mars::LaserRangeFinder, :as => "driver"

      class Cmp < SimulatedDevice
          add [Dev::Mars::LaserRangeFinder,Base::LaserRangeFinderSrv], :as => "task"
          export task_child.scans_port
          provides Base::LaserRangeFinderSrv, :as => "scans"
      end
    end

    class HighResRangeFinder
        argument :cameras

        forward :lost_mars_connection => :failed
        driver_for Dev::Mars::HighResRangeFinder, :as => "driver"

        transformer do
            associate_frame_to_ports 'high_res_range_finder', 'pointcloud'
        end

        # Camera can be added to increase the viewing angle, but needs to be added after start of
        # the device
        def self.with_cameras(name, *viewing_angles)
            if viewing_angles.empty?
                viewing_angles = [90,180,270]
            end
            cameras = Hash.new
            viewing_angles.each {|v| cameras["#{name}#{v}"] = v }
            to_instance_requirements.
                with_arguments('cameras' => cameras)
        end

        class Cmp < SimulatedDevice
            add [Dev::Mars::HighResRangeFinder,Base::PointcloudProviderSrv], :as => "task"
            export task_child.pointcloud_port
            provides Base::PointcloudProviderSrv, :as => 'pointcloud_provider'
        end

        on :start do |event|
            cameras = arguments[:cameras]
            if cameras
                cameras.each do |name, angle|
                    puts "#{__FILE__}: Simulation::MarsHighResRangeFinder adding camera '#{name}' for angle '#{angle}'"
                    orocos_task.addCamera(name, angle)
                end
            end
        end
    end

    class RotatingLaserRangeFinder
      forward :lost_mars_connection => :failed
      driver_for Dev::Mars::RotatingLaserRangeFinder, :as => "driver"

      class Cmp < SimulatedDevice
          add [Dev::Mars::RotatingLaserRangeFinder,Base::PointcloudProviderSrv], :as => "task"
          export task_child.pointcloud_port
          provides Base::PointcloudProviderSrv, :as => 'pointcloud_provider'
      end
    end

    def self.define_simulated_device(profile, name, model)
        device = profile.robot.device model, :as => name
        # The SimulatedDevice subclasses expect the MARS task,not the device
        # model. Resolve the task from the device definition by removing the
        # data service selection (#to_component_model)
        #
        # to_instance_requirements is there to convert the device object into
        # an InstanceRequirements object
        device = device.to_instance_requirements.to_component_model
        composition = composition_from_device(model)
        device = yield(device) if block_given?
        composition = composition.use('task' => device)
        profile.define name, composition
        model
    end

    def self.composition_from_device(device_model, options = nil)
        SimulatedDevice.each_submodel do |cmp_m|
            if cmp_m.task_child.fullfills?(device_model)
                return cmp_m
            end
        end
        raise ArgumentError, "no composition found to represent devices of type #{device_model} in MARS"
    end
end


class Syskit::Actions::Profile
    #
    # Instead of doing
    #   define 'dynamixel', Model
    #
    # Do
    #
    #   define_simulated_device 'dynamixel', Dev::Simulation::Sonar
    #
    def define_mars_device(name, model, &block)
        Mars.define_simulated_device(self, name, model, &block)
    end
end

